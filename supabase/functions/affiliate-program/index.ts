import { createClient } from 'jsr:@supabase/supabase-js@2';
import { initializeApp, cert, getApps } from 'npm:firebase-admin/app';
import { getAuth } from 'npm:firebase-admin/auth';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {...corsHeaders, 'Content-Type': 'application/json'},
  });
}

function getEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing env var: ${name}`);
  return value;
}

function initFirebaseAdmin() {
  if (getApps().length > 0) return;
  initializeApp({
    credential: cert({
      projectId: getEnv('FIREBASE_PROJECT_ID'),
      clientEmail: getEnv('FIREBASE_CLIENT_EMAIL'),
      privateKey: getEnv('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n'),
    }),
  });
}

function normalizeCode(value: unknown): string {
  if (typeof value !== 'string') return '';
  const input = value.trim();
  if (!input) return '';

  try {
    const uri = new URL(input);
    const queryCode = uri.searchParams.get('ref');
    if (queryCode) return queryCode.trim().toUpperCase();

    const segments = uri.pathname.split('/').filter(Boolean);
    const refIndex = segments.findIndex(
      (segment) => segment.toLowerCase() === 'ref',
    );
    if (refIndex >= 0 && refIndex + 1 < segments.length) {
      return segments[refIndex + 1].trim().toUpperCase();
    }
  } catch {
    // Plain promo codes are expected and are handled below.
  }

  const embeddedCode = input.match(
    /(?:[?&]ref=|\/ref\/)([a-z0-9]{4,20})(?:[^a-z0-9]|$)/i,
  );
  return (embeddedCode?.[1] ?? input).trim().toUpperCase();
}

function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  if (
    typeof error === 'object' &&
    error !== null &&
    'message' in error &&
    typeof error.message === 'string'
  ) {
    return error.message;
  }
  return 'Request failed';
}

async function requireUser(
  serviceClient: ReturnType<typeof createClient>,
  authHeader: string,
) {
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) throw new Error('Unauthorized');

  const decoded = await getAuth().verifyIdToken(token);
  const {data, error} = await serviceClient
    .from('users')
    .select('id, uid, isAffiliate, isAdmin')
    .eq('uid', decoded.uid)
    .maybeSingle();

  if (error || !data) throw new Error('User profile not found');
  return data;
}

function requireAdmin(user: {isAdmin?: boolean}) {
  if (user.isAdmin !== true) throw new Error('Forbidden');
}

async function processNotificationQueue() {
  const workerSecret = Deno.env.get('PROCESS_QUEUE_SECRET');
  if (!workerSecret) {
    console.error('[affiliate-program] PROCESS_QUEUE_SECRET is not configured');
    return;
  }

  try {
    const response = await fetch(
      `${getEnv('SUPABASE_URL')}/functions/v1/process-notification-jobs`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-process-queue-secret': workerSecret,
        },
        body: JSON.stringify({limit: 50}),
      },
    );
    if (!response.ok) {
      console.error(
        '[affiliate-program] notification worker failed',
        response.status,
        await response.text(),
      );
    }
  } catch (error) {
    console.error(
      '[affiliate-program] notification worker request failed',
      errorMessage(error),
    );
  }
}

async function validateCode(
  serviceClient: ReturnType<typeof createClient>,
  code: string,
  subtotal: number,
  currentUserId?: number,
) {
  const {data: affiliateCode, error: affiliateError} = await serviceClient
    .from('affiliate_codes')
    .select(
      'id, affiliateID, code, customerDiscountPercentage, affiliateCommissionPercentage',
    )
    .ilike('code', code)
    .eq('isActive', true)
    .maybeSingle();

  if (affiliateError) throw affiliateError;
  if (affiliateCode) {
    if (affiliateCode.affiliateID === currentUserId) {
      throw new Error('Affiliates cannot use their own code');
    }
    const discountPercentage = Number(
      affiliateCode.customerDiscountPercentage,
    );
    return {
      valid: true,
      code: affiliateCode.code,
      type: 'affiliate',
      discount_percentage: discountPercentage,
      discount_amount: Math.min(
        subtotal,
        Math.round(subtotal * discountPercentage) / 100,
      ),
    };
  }

  const {data: voucher, error: voucherError} = await serviceClient
    .from('vouchers')
    .select('voucherCode, voucherAmount, voucherPercentage')
    .ilike('voucherCode', code)
    .eq('isActive', true)
    .maybeSingle();

  if (voucherError) throw voucherError;
  if (voucher) {
    const fixed = voucher.voucherAmount == null
      ? null
      : Number(voucher.voucherAmount);
    const percentage = voucher.voucherPercentage == null
      ? null
      : Number(voucher.voucherPercentage);
    const amount = fixed ?? subtotal * (percentage ?? 0) / 100;
    return {
      valid: true,
      code: voucher.voucherCode,
      type: 'voucher',
      discount_percentage: percentage,
      discount_amount: Math.min(subtotal, Math.round(amount * 100) / 100),
    };
  }

  const now = new Date().toISOString();
  const {data: promotion, error: promotionError} = await serviceClient
    .from('promotions')
    .select('promotionCode, promotionDiscount, expiry_date')
    .ilike('promotionCode', code)
    .or(`expiry_date.is.null,expiry_date.gt.${now}`)
    .maybeSingle();

  if (promotionError) throw promotionError;
  if (promotion) {
    return {
      valid: true,
      code: promotion.promotionCode,
      type: 'promotion',
      discount_percentage: null,
      discount_amount: Math.min(
        subtotal,
        Math.round(Number(promotion.promotionDiscount) * 100) / 100,
      ),
    };
  }

  return {valid: false, code, type: null, discount_amount: 0};
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', {headers: corsHeaders});
  if (req.method !== 'POST') return json({error: 'Method not allowed'}, 405);

  try {
    initFirebaseAdmin();
    const serviceClient = createClient(
      getEnv('SUPABASE_URL'),
      getEnv('SUPABASE_SERVICE_ROLE_KEY'),
      {auth: {persistSession: false, autoRefreshToken: false}},
    );
    const body = await req.json() as Record<string, unknown>;
    const action = typeof body.action === 'string' ? body.action : '';

    if (action === 'validate_code') {
      const code = normalizeCode(body.code);
      const subtotal = Math.max(0, Number(body.subtotal) || 0);
      if (!code) return json({valid: false, code: '', discount_amount: 0});
      const currentUser = body.check_self === true
        ? await requireUser(
          serviceClient,
          req.headers.get('authorization') ?? '',
        )
        : null;
      return json(
        await validateCode(serviceClient, code, subtotal, currentUser?.id),
      );
    }

    const user = await requireUser(
      serviceClient,
      req.headers.get('authorization') ?? '',
    );

    if (action === 'save_attribution') {
      const code = normalizeCode(body.code);
      if (!code) throw new Error('Invalid affiliate code');
      const {data, error} = await serviceClient.rpc(
        'save_affiliate_attribution',
        {
          p_user_uid: user.uid,
          p_code: code,
          p_source: 'link',
          p_item_id: Number(body.item_id) || null,
        },
      );
      if (error) throw error;
      return json(data);
    }

    if (action === 'affiliate_application_status') {
      if (user.isAffiliate === true) {
        return json({is_affiliate: true, application: null});
      }

      const {data, error} = await serviceClient
        .from('affiliate_applications')
        .select(
          'id, preferredCode, message, status, adminNote, reviewedAt, createdAt',
        )
        .eq('userID', user.id)
        .order('createdAt', {ascending: false})
        .limit(1)
        .maybeSingle();
      if (error) throw error;
      return json({is_affiliate: false, application: data});
    }

    if (action === 'submit_affiliate_application') {
      const {data, error} = await serviceClient.rpc(
        'submit_affiliate_application',
        {
          p_user_uid: user.uid,
          p_preferred_code: normalizeCode(body.preferred_code),
          p_message: String(body.message ?? ''),
        },
      );
      if (error) throw error;
      await processNotificationQueue();
      return json(data);
    }

    if (action === 'affiliate_profile') {
      if (user.isAffiliate !== true) throw new Error('Forbidden');
      const {data, error} = await serviceClient
        .from('affiliate_codes')
        .select(
          'code, customerDiscountPercentage, affiliateCommissionPercentage',
        )
        .eq('affiliateID', user.id)
        .maybeSingle();
      if (error) throw error;
      if (!data) throw new Error('Affiliate code not found');
      return json({profile: data});
    }

    if (action === 'active_attribution') {
      const {data: attribution, error: attributionError} = await serviceClient
        .from('customer_affiliate_attributions')
        .select('affiliateCodeID, source, expiresAt')
        .eq('userID', user.id)
        .eq('isActive', true)
        .gt('expiresAt', new Date().toISOString())
        .order('attributedAt', {ascending: false})
        .limit(1)
        .maybeSingle();
      if (attributionError) throw attributionError;
      if (!attribution) return json({attribution: null});

      const {data: code, error: codeError} = await serviceClient
        .from('affiliate_codes')
        .select('code, customerDiscountPercentage')
        .eq('id', attribution.affiliateCodeID)
        .eq('isActive', true)
        .maybeSingle();
      if (codeError) throw codeError;
      if (!code) return json({attribution: null});

      return json({
        attribution: {
          code: code.code,
          source: attribution.source,
          customer_discount_percentage: code.customerDiscountPercentage,
          expires_at: attribution.expiresAt,
        },
      });
    }

    if (action === 'place_order') {
      const {data, error} = await serviceClient.rpc('place_order_secure', {
        p_user_uid: user.uid,
        p_address_id: Number(body.address_id),
        p_phone: String(body.phone ?? ''),
        p_notes: String(body.notes ?? ''),
        p_promo_code: normalizeCode(body.promo_code) || null,
        p_affiliate_source: body.affiliate_source === 'link'
          ? 'link'
          : 'manual',
      });
      if (error) throw error;
      await processNotificationQueue();
      return json(data);
    }

    if (action === 'admin_affiliate_queue') {
      requireAdmin(user);
      const [applicationsResult, payoutsResult] = await Promise.all([
        serviceClient
          .from('affiliate_applications')
          .select(
            '*, users!affiliate_applications_userID_fkey(name, phone)',
          )
          .eq('status', 'Pending')
          .order('createdAt', {ascending: true}),
        serviceClient
          .from('payout_requests')
          .select('*, users!payout_requests_affiliateID_fkey(name, phone)')
          .eq('status', 'Pending')
          .order('created_at', {ascending: true}),
      ]);
      if (applicationsResult.error) throw applicationsResult.error;
      if (payoutsResult.error) throw payoutsResult.error;
      return json({
        applications: applicationsResult.data ?? [],
        payouts: payoutsResult.data ?? [],
      });
    }

    if (action === 'review_affiliate_application') {
      requireAdmin(user);
      const {data, error} = await serviceClient.rpc(
        'review_affiliate_application',
        {
          p_admin_uid: user.uid,
          p_application_id: Number(body.application_id),
          p_decision: String(body.decision ?? ''),
          p_admin_note: String(body.admin_note ?? ''),
        },
      );
      if (error) throw error;
      await processNotificationQueue();
      return json(data);
    }

    if (action === 'review_payout') {
      requireAdmin(user);
      const {data, error} = await serviceClient.rpc(
        'review_affiliate_payout',
        {
          p_admin_uid: user.uid,
          p_request_id: Number(body.request_id),
          p_decision: String(body.decision ?? ''),
          p_payment_reference: body.payment_reference == null
            ? null
            : String(body.payment_reference),
          p_admin_note: String(body.admin_note ?? ''),
        },
      );
      if (error) throw error;
      await processNotificationQueue();
      return json(data);
    }

    if (action === 'set_affiliate_status') {
      requireAdmin(user);
      const userId = Number(body.user_id);
      if (!Number.isInteger(userId) || userId <= 0) {
        throw new Error('Invalid user');
      }
      const {error} = await serviceClient
        .from('users')
        .update({isAffiliate: body.is_affiliate === true})
        .eq('id', userId);
      if (error) throw error;
      return json({user_id: userId, is_affiliate: body.is_affiliate === true});
    }

    if (action === 'affiliate_dashboard') {
      if (user.isAffiliate !== true) throw new Error('Forbidden');

      const [
        codeResult,
        commissionsResult,
        ordersResult,
        payoutsResult,
      ] = await Promise.all([
        serviceClient
          .from('affiliate_codes')
          .select(
            'code, customerDiscountPercentage, affiliateCommissionPercentage',
          )
          .eq('affiliateID', user.id)
          .maybeSingle(),
        serviceClient
          .from('affiliate_commissions')
          .select('amount, status')
          .eq('affiliateID', user.id),
        serviceClient
          .from('order_master')
          .select('*')
          .eq('affiliateID', user.id)
          .order('created_at', {ascending: false}),
        serviceClient
          .from('payout_requests')
          .select('*')
          .eq('affiliateID', user.id)
          .order('created_at', {ascending: false}),
      ]);

      const firstError = [
        codeResult.error,
        commissionsResult.error,
        ordersResult.error,
        payoutsResult.error,
      ].find(Boolean);
      if (firstError) throw firstError;

      let totalEarnings = 0;
      let pendingEarnings = 0;
      let availableBalance = 0;
      for (const row of commissionsResult.data ?? []) {
        const amount = Number(row.amount) || 0;
        if (row.status !== 'void') totalEarnings += amount;
        if (row.status === 'pending') pendingEarnings += amount;
        if (row.status === 'available') availableBalance += amount;
      }

      return json({
        profile: codeResult.data,
        total_earnings: totalEarnings,
        pending_earnings: pendingEarnings,
        available_balance: availableBalance,
        orders: ordersResult.data ?? [],
        payouts: payoutsResult.data ?? [],
      });
    }

    if (action === 'update_code') {
      if (user.isAffiliate !== true) throw new Error('Forbidden');
      const code = normalizeCode(body.code);
      if (!/^[A-Z0-9]{4,20}$/.test(code)) {
        throw new Error('Code must contain 4-20 letters or numbers');
      }

      const {data, error} = await serviceClient
        .from('affiliate_codes')
        .update({code, updatedAt: new Date().toISOString()})
        .eq('affiliateID', user.id)
        .select(
          'code, customerDiscountPercentage, affiliateCommissionPercentage',
        )
        .single();
      if (error) {
        if (error.code === '23505') throw new Error('Code is already in use');
        throw error;
      }
      return json({profile: data});
    }

    if (action === 'request_payout') {
      if (user.isAffiliate !== true) throw new Error('Forbidden');
      const {data, error} = await serviceClient.rpc(
        'request_affiliate_payout',
        {
          p_user_uid: user.uid,
          p_payout_method: String(body.payout_method ?? ''),
          p_payout_account: String(body.payout_account ?? ''),
        },
      );
      if (error) throw error;
      await processNotificationQueue();
      return json(data);
    }

    throw new Error('Unknown action');
  } catch (error) {
    const message = errorMessage(error);
    const status = message === 'Unauthorized'
      ? 401
      : message === 'Forbidden'
      ? 403
      : 400;
    console.error('[affiliate-program]', message);
    return json({error: message}, status);
  }
});
