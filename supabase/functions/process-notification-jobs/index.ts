import { createClient } from 'jsr:@supabase/supabase-js@2';
import { initializeApp, cert, getApps } from 'npm:firebase-admin/app';
import { getAuth } from 'npm:firebase-admin/auth';
import { getMessaging } from 'npm:firebase-admin/messaging';

type NotificationJob = {
  id: number;
  eventType: string;
  title: string;
  body: string;
  payload: Record<string, unknown>;
  isAndroidOnly: boolean;
  isArabicOnly: boolean;
  status: string;
  attempts: number;
};

type DeviceTokenRow = {
  fcmToken: string;
};

const INVALID_TOKEN_CODES = new Set([
  'messaging/invalid-argument',
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

function getEnv(name: string, fallbackName?: string): string {
  const value = Deno.env.get(name) ?? (fallbackName ? Deno.env.get(fallbackName) : undefined);
  if (!value) {
    throw new Error(`Missing env var: ${fallbackName ? `${name} or ${fallbackName}` : name}`);
  }
  return value;
}

function initFirebaseAdmin() {
  if (getApps().length > 0) return;

  const projectId = getEnv('FIREBASE_PROJECT_ID');
  const clientEmail = getEnv('FIREBASE_CLIENT_EMAIL');
  const privateKey = getEnv('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n');

  initializeApp({
    credential: cert({ projectId, clientEmail, privateKey }),
    projectId,
  });
}

function payloadToData(payload: Record<string, unknown>): Record<string, string> {
  const data: Record<string, string> = {};
  for (const [k, v] of Object.entries(payload ?? {})) {
    if (v === null || v === undefined) continue;
    data[k] = typeof v === 'string' ? v : JSON.stringify(v);
  }
  return data;
}

async function requireAdminUser(
  serviceClient: ReturnType<typeof createClient>,
  authHeader: string,
) {
  const idToken = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!idToken) {
    throw new Error('Unauthorized');
  }

  const decodedToken = await getAuth().verifyIdToken(idToken);
  const uid = decodedToken.uid;
  const { data: adminRow, error: adminError } = await serviceClient
    .from('users')
    .select('isAdmin')
    .eq('uid', uid)
    .maybeSingle();

  if (adminError || adminRow?.isAdmin != true) {
    throw new Error('Forbidden');
  }
}

function isValidWorkerSecret(req: Request): boolean {
  const expected = Deno.env.get('PROCESS_QUEUE_SECRET');
  if (!expected) return false;
  const provided = req.headers.get('x-process-queue-secret') ?? '';
  return provided.length > 0 && provided === expected;
}

async function resolveOrderUserUid(serviceClient: ReturnType<typeof createClient>, orderId: number): Promise<string | null> {
  const { data: orderRow, error: orderError } = await serviceClient
    .from('order_master')
    .select('userID')
    .eq('id', orderId)
    .maybeSingle();

  if (orderError || !orderRow) return null;

  const userId = orderRow.userID as number | null;
  if (!userId) return null;

  const { data: userRow, error: userError } = await serviceClient
    .from('users')
    .select('uid')
    .eq('id', userId)
    .maybeSingle();

  if (userError || !userRow) return null;
  return userRow.uid as string;
}

async function fetchTokensForJob(
  serviceClient: ReturnType<typeof createClient>,
  job: NotificationJob,
): Promise<string[]> {
  let query = serviceClient
    .from('device_tokens')
    .select('fcmToken')
    .eq('isActive', true);

  if (job.isAndroidOnly) {
    query = query.eq('isAndroid', true);
  }

  if (job.isArabicOnly) {
    query = query.eq('isArabic', true);
  }

  if (job.payload?.target_audience === 'admins') {
    const { data: admins, error: adminsError } = await serviceClient
      .from('users')
      .select('uid')
      .eq('isAdmin', true);
    if (adminsError || !admins || admins.length === 0) return [];

    const adminUids = admins
      .map((row) => row.uid)
      .filter((uid) => typeof uid === 'string' && uid.length > 0);
    if (adminUids.length === 0) return [];
    query = query.in('userID', adminUids);
  } else if (
    typeof job.payload?.target_user_uid === 'string' &&
    job.payload.target_user_uid.length > 0
  ) {
    query = query.eq('userID', job.payload.target_user_uid);
  } else if (job.eventType === 'order_status_changed') {
    const orderIdRaw = job.payload?.order_id;
    const orderId = typeof orderIdRaw === 'number'
      ? orderIdRaw
      : Number(orderIdRaw);

    if (!Number.isFinite(orderId)) return [];

    const uid = await resolveOrderUserUid(serviceClient, orderId);
    if (!uid) return [];

    query = query.eq('userID', uid);
  }

  const { data, error } = await query;
  if (error || !data) return [];
  return (data as DeviceTokenRow[])
    .map((r) => r.fcmToken)
    .filter((t) => typeof t === 'string' && t.length > 0);
}

async function deactivateInvalidTokens(
  serviceClient: ReturnType<typeof createClient>,
  invalidTokens: string[],
) {
  if (invalidTokens.length === 0) return;

  await serviceClient
    .from('device_tokens')
    .update({
      isActive: false,
      lastSeen: new Date().toISOString(),
    })
    .in('fcmToken', invalidTokens);
}

async function processSingleJob(
  serviceClient: ReturnType<typeof createClient>,
  job: NotificationJob,
) {
  const tokens = await fetchTokensForJob(serviceClient, job);

  if (tokens.length == 0) {
    await serviceClient.rpc('complete_notification_job', {
      p_job_id: job.id,
      p_status: 'sent',
      p_last_error: null,
    });
    return { id: job.id, sent: 0, failed: 0, note: 'no_tokens' };
  }

  const data = payloadToData(job.payload ?? {});
  const messaging = getMessaging();

  let successCount = 0;
  let failureCount = 0;
  const invalidTokens: string[] = [];
  const failureReasons = new Map<string, number>();

  for (let i = 0; i < tokens.length; i += 500) {
    const chunk = tokens.slice(i, i + 500);
    const response = await messaging.sendEachForMulticast({
      tokens: chunk,
      notification: {
        title: job.title,
        body: job.body,
      },
      data,
      android: {
        priority: 'high',
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    });

    successCount += response.successCount;
    failureCount += response.failureCount;

    for (let idx = 0; idx < response.responses.length; idx++) {
      const r = response.responses[idx];
      if (r.success) continue;
      const code = r.error?.code ?? '';
      const message = r.error?.message ?? 'Unknown Firebase error';
      const reason = code ? `${code}: ${message}` : message;
      failureReasons.set(reason, (failureReasons.get(reason) ?? 0) + 1);
      if (INVALID_TOKEN_CODES.has(code)) {
        invalidTokens.push(chunk[idx]);
      }
    }
  }

  await deactivateInvalidTokens(serviceClient, invalidTokens);

  await serviceClient.rpc('complete_notification_job', {
    p_job_id: job.id,
    p_status: failureCount > 0 && successCount === 0 ? 'failed' : 'sent',
    p_last_error: failureCount > 0
      ? Array.from(failureReasons.entries())
        .map(([reason, count]) => `${count}x ${reason}`)
        .join(' | ')
      : null,
  });

  return {
    id: job.id,
    sent: successCount,
    failed: failureCount,
    deactivatedTokens: invalidTokens.length,
  };
}

Deno.serve(async (req) => {
  try {
    initFirebaseAdmin();

    const supabaseUrl = getEnv('SUPABASE_URL');
    const supabaseServiceRole = getEnv('SUPABASE_SERVICE_ROLE_KEY', 'SERVICE_ROLE_KEY');

    const authHeader = req.headers.get('Authorization') ?? '';
    const hasBearerToken = authHeader.startsWith('Bearer ');
    const hasWorkerSecret = isValidWorkerSecret(req);

    if (!hasBearerToken && !hasWorkerSecret) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const serviceClient = createClient(supabaseUrl, supabaseServiceRole);

    if (hasBearerToken) {
      await requireAdminUser(
        serviceClient,
        authHeader,
      );
    }

    const body = await req.json().catch(() => ({}));
    const limit = Number(body?.limit ?? 20);

    const { data: claimed, error: claimError } = await serviceClient.rpc(
      'claim_notification_jobs',
      { p_limit: Number.isFinite(limit) ? limit : 20 },
    );

    if (claimError) {
      throw claimError;
    }

    const jobs = (claimed ?? []) as NotificationJob[];

    const results: Array<Record<string, unknown>> = [];
    for (const job of jobs) {
      try {
        const result = await processSingleJob(serviceClient, job);
        results.push({ ok: true, ...result });
      } catch (e) {
        const message = `${e}`;
        await serviceClient.rpc('complete_notification_job', {
          p_job_id: job.id,
          p_status: 'failed',
          p_last_error: message,
        });
        results.push({ ok: false, id: job.id, error: message });
      }
    }

    return new Response(
      JSON.stringify({
        claimed: jobs.length,
        processed: results.length,
        results,
      }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: `${e}` }),
      {
        status: /Forbidden/.test(`${e}`) ? 403 : /Unauthorized/.test(`${e}`) ? 401 : 500,
        headers: { 'Content-Type': 'application/json' },
      },
    );
  }
});
