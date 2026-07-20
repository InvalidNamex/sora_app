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
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function env(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing env var: ${name}`);
  return value;
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

function errorMessage(error: unknown): string {
  if (error instanceof Error && error.message.trim()) return error.message;
  if (typeof error === 'string' && error.trim()) return error;
  if (error && typeof error === 'object') {
    const record = error as Record<string, unknown>;
    for (const key of ['message', 'error', 'details', 'hint']) {
      const value = record[key];
      if (typeof value === 'string' && value.trim()) return value;
    }
  }
  return 'Could not delete the account. Please try again.';
}

function isFirebaseUserMissing(error: unknown): boolean {
  if (!error || typeof error !== 'object') return false;
  const code = String((error as Record<string, unknown>).code ?? '');
  return code === 'auth/user-not-found';
}

async function deleteFirebaseUser(uid: string) {
  let lastError: unknown;
  for (let attempt = 0; attempt < 3; attempt += 1) {
    try {
      await getAuth().deleteUser(uid);
      return;
    } catch (error) {
      if (isFirebaseUserMissing(error)) return;
      lastError = error;
      if (attempt < 2) {
        await new Promise((resolve) => setTimeout(resolve, 250 * (attempt + 1)));
      }
    }
  }
  throw lastError;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  try {
    const body = await req.json() as Record<string, unknown>;
    if (body.confirmation !== 'DELETE') {
      return json({ error: 'Deletion confirmation is required' }, 400);
    }

    initFirebaseAdmin();
    const authHeader = req.headers.get('authorization') ?? '';
    const token = authHeader.replace(/^Bearer\s+/i, '').trim();
    if (!token) return json({ error: 'Unauthorized' }, 401);

    const decoded = await getAuth().verifyIdToken(token);
    const uid = decoded.uid;
    const serviceClient = createClient(
      env('SUPABASE_URL'),
      env('SUPABASE_SERVICE_ROLE_KEY'),
      { auth: { persistSession: false, autoRefreshToken: false } },
    );

    const { error: beginError } = await serviceClient.rpc(
      'begin_account_deletion',
      { p_user_uid: uid },
    );
    if (beginError) throw beginError;

    // The Apple authorization token is revoked by the native app immediately
    // before this request. Firebase Admin removes the Firebase credential for
    // every provider here.
    await deleteFirebaseUser(uid);

    const { data: finalized, error: finalizeError } = await serviceClient.rpc(
      'finalize_account_deletion',
      { p_user_uid: uid },
    );
    if (finalizeError || finalized !== true) {
      // Personal data and the Firebase credential are already deleted. Do not
      // turn a completed deletion into a client-visible failure merely because
      // the final pseudonymous UID replacement needs operational follow-up.
      console.error('[delete-account] identity finalization failed', {
        error: finalizeError,
        finalized,
      });
    }

    return json({ deleted: true });
  } catch (error) {
    const message = errorMessage(error);
    const lower = message.toLowerCase();
    const status = lower.includes('unauthorized') ||
        lower.includes('id token')
      ? 401
      : lower.includes('not found')
      ? 404
      : 500;
    console.error('[delete-account]', error);
    return json({ error: message }, status);
  }
});
