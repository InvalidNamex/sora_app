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

function env(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing env var: ${name}`);
  return value;
}

function errorMessage(error: unknown): string {
  if (error instanceof Error && error.message.trim()) return error.message;
  if (typeof error === 'string' && error.trim()) return error;
  if (error && typeof error === 'object') {
    const record = error as Record<string, unknown>;
    for (const key of ['message', 'error', 'details', 'hint']) {
      const value = record[key];
      if (typeof value === 'string' && value.trim()) return value;
      if (value && typeof value === 'object') {
        const nested = errorMessage(value);
        if (nested !== 'Bundle request failed') return nested;
      }
    }
  }
  return 'Bundle request failed';
}

function initFirebaseAdmin() {
  if (getApps().length > 0) return;
  initializeApp({
    credential: cert({
      projectId: env('FIREBASE_PROJECT_ID'),
      clientEmail: env('FIREBASE_CLIENT_EMAIL'),
      privateKey: env('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n'),
    }),
  });
}

async function requireAdmin(
  serviceClient: ReturnType<typeof createClient>,
  authHeader: string,
) {
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) throw new Error('Unauthorized');
  const decoded = await getAuth().verifyIdToken(token);
  const {data, error} = await serviceClient
    .from('users')
    .select('id, isAdmin')
    .eq('uid', decoded.uid)
    .maybeSingle();
  if (error || !data) throw new Error('Unauthorized');
  if (data.isAdmin !== true) throw new Error('Forbidden');
  return data.id as number;
}

const imageExtensions = new Set(['jpg', 'jpeg', 'png', 'webp']);

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', {headers: corsHeaders});
  if (req.method !== 'POST') return json({error: 'Method not allowed'}, 405);

  try {
    initFirebaseAdmin();
    const serviceClient = createClient(
      env('SUPABASE_URL'),
      env('SUPABASE_SERVICE_ROLE_KEY'),
      {auth: {persistSession: false, autoRefreshToken: false}},
    );
    await requireAdmin(
      serviceClient,
      req.headers.get('authorization') ?? '',
    );
    const body = await req.json() as Record<string, unknown>;
    const action = String(body.action ?? '');

    if (action === 'list_bundles') {
      const {data, error} = await serviceClient
        .from('bundle_deals')
        .select(
          'id, title, titleEN, description, descriptionEN, bannerImage, ' +
          'dealPrice, isActive, sortOrder, ' +
          'bundle_deal_items(id, bundleID, quantity, ' +
          'item_properties(id, itemID, size, image, PropertyDescription, ' +
          'propertyDescriptionEN, price, inStock, isDefault, ' +
          'items(itemName, itemNameEN)))',
        )
        .order('sortOrder')
        .order('id', {ascending: false});
      if (error) throw error;
      return json({bundles: data ?? []});
    }

    if (action === 'create_upload') {
      const extension = String(body.extension ?? '').toLowerCase();
      if (!imageExtensions.has(extension)) {
        return json({error: 'Unsupported image type'}, 400);
      }
      const path = `banners/${crypto.randomUUID()}.${extension}`;
      const {data, error} = await serviceClient.storage
        .from('bundle_banner')
        .createSignedUploadUrl(path);
      if (error || !data) throw error ?? new Error('Could not sign upload');
      return json({
        path,
        token: data.token,
        publicUrl: serviceClient.storage
          .from('bundle_banner')
          .getPublicUrl(path).data.publicUrl,
      });
    }

    if (action === 'save_bundle') {
      const id = Number(body.id) || null;
      const title = String(body.title ?? '').trim();
      const dealPrice = Number(body.deal_price);
      const bannerImage = String(body.banner_image ?? '').trim();
      const rawItems = Array.isArray(body.items) ? body.items : [];
      if (!title || !bannerImage || !Number.isFinite(dealPrice) ||
          dealPrice <= 0 || rawItems.length === 0) {
        return json({error: 'Complete all required bundle fields'}, 400);
      }

      const payload = {
        title,
        titleEN: String(body.title_en ?? '').trim(),
        description: String(body.description ?? '').trim(),
        descriptionEN: String(body.description_en ?? '').trim(),
        bannerImage,
        dealPrice,
        isActive: body.is_active !== false,
        sortOrder: Math.trunc(Number(body.sort_order) || 0),
        updatedAt: new Date().toISOString(),
      };

      const itemRows = rawItems.map((raw) => {
        const item = raw as Record<string, unknown>;
        return {
          propertyID: Math.trunc(Number(item.property_id)),
          quantity: Math.trunc(Number(item.quantity)),
        };
      });
      if (itemRows.some((item) =>
        item.propertyID <= 0 || item.quantity <= 0
      )) {
        throw new Error('Bundle item quantities must be positive');
      }
      if (new Set(itemRows.map((item) => item.propertyID)).size !==
        itemRows.length) {
        throw new Error('A bundle cannot contain the same property twice');
      }

      const {data: savedId, error: saveError} = await serviceClient.rpc(
        'admin_save_bundle',
        {
          p_bundle_id: id,
          p_bundle: payload,
          p_items: itemRows,
        },
      );
      if (saveError || !savedId) throw saveError ??
        new Error('Could not save bundle');
      const bundleId = Number(savedId);
      return json({id: bundleId});
    }

    if (action === 'delete_bundle') {
      const id = Math.trunc(Number(body.id));
      if (id <= 0) return json({error: 'Invalid bundle'}, 400);
      const {error} = await serviceClient
        .from('bundle_deals')
        .delete()
        .eq('id', id);
      if (error) throw error;
      return json({deleted: true});
    }

    return json({error: 'Unknown action'}, 400);
  } catch (error) {
    const message = errorMessage(error);
    const status = message === 'Unauthorized'
      ? 401
      : message === 'Forbidden'
      ? 403
      : 400;
    console.error('[manage-bundles]', error);
    return json({error: message}, status);
  }
});
