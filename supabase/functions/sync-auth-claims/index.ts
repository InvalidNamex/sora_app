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
  const projectId = env('FIREBASE_PROJECT_ID');
  initializeApp({
    credential: cert({
      projectId,
      clientEmail: env('FIREBASE_CLIENT_EMAIL'),
      privateKey: env('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n'),
    }),
    projectId,
  });
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  try {
    initFirebaseAdmin();
    const token = (request.headers.get('authorization') ?? '')
      .replace(/^Bearer\s+/i, '')
      .trim();
    if (!token) return json({ error: 'Unauthorized' }, 401);

    const decoded = await getAuth().verifyIdToken(token);
    const user = await getAuth().getUser(decoded.uid);
    const existingClaims = user.customClaims ?? {};
    if (existingClaims.role === 'authenticated') {
      return json({ token_refresh_required: false });
    }

    await getAuth().setCustomUserClaims(decoded.uid, {
      ...existingClaims,
      role: 'authenticated',
    });
    return json({ token_refresh_required: true });
  } catch (error) {
    console.error('[sync-auth-claims]', error);
    return json({ error: 'Unable to provision authentication claims' }, 401);
  }
});
