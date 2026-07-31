import { createClient } from 'jsr:@supabase/supabase-js@2';
import { initializeApp, cert, getApps } from 'npm:firebase-admin/app';
import { getAuth } from 'npm:firebase-admin/auth';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const statuses = new Set(['pending', 'approved', 'rejected']);

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function getEnv(name: string, fallbackName?: string): string {
  const value = Deno.env.get(name) ??
    (fallbackName ? Deno.env.get(fallbackName) : undefined);
  if (!value) throw new Error(`Missing env var: ${name}`);
  return value;
}

function initFirebaseAdmin() {
  if (getApps().length > 0) return;
  const projectId = getEnv('FIREBASE_PROJECT_ID');
  initializeApp({
    credential: cert({
      projectId,
      clientEmail: getEnv('FIREBASE_CLIENT_EMAIL'),
      privateKey: getEnv('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n'),
    }),
    projectId,
  });
}

function stringValue(value: unknown, maxLength: number): string {
  if (typeof value !== 'string') return '';
  return value.trim().slice(0, maxLength);
}

async function requireUser(
  serviceClient: ReturnType<typeof createClient>,
  authHeader: string,
) {
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) throw new Error('Unauthorized');

  const decoded = await getAuth().verifyIdToken(token);
  const { data, error } = await serviceClient
    .from('users')
    .select('id, uid, isAdmin')
    .eq('uid', decoded.uid)
    .maybeSingle();
  if (error) throw error;
  if (!data) throw new Error('User profile not found');
  return data as { id: number; uid: string; isAdmin: boolean };
}

function requireAdmin(user: { isAdmin: boolean }) {
  if (user.isAdmin !== true) throw new Error('Forbidden');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  try {
    initFirebaseAdmin();
    const serviceClient = createClient(
      getEnv('SUPABASE_URL'),
      getEnv('SUPABASE_SERVICE_ROLE_KEY', 'SERVICE_ROLE_KEY'),
    );
    const user = await requireUser(
      serviceClient,
      req.headers.get('Authorization') ?? '',
    );
    const body = await req.json() as Record<string, unknown>;
    const action = stringValue(body.action, 40);

    if (action === 'submit') {
      const itemName = stringValue(body.item_name, 160);
      const brandName = stringValue(body.brand_name, 160);
      const details = stringValue(body.details, 2000);
      if (itemName.length < 2) {
        return json({ error: 'Item name is required' }, 400);
      }

      const { data, error } = await serviceClient
        .from('item_suggestions')
        .insert({
          user_id: user.id,
          item_name: itemName,
          brand_name: brandName || null,
          details: details || null,
        })
        .select('id')
        .single();
      if (error) throw error;
      return json({ id: data.id, submitted: true }, 201);
    }

    requireAdmin(user);

    if (action === 'list') {
      const status = stringValue(body.status, 20);
      let query = serviceClient
        .from('item_suggestions')
        .select(
          'id, user_id, item_name, brand_name, details, status, admin_note, ' +
            'created_at, updated_at, users!item_suggestions_user_id_fkey' +
            '(name, phone, email)',
        )
        .order('created_at', { ascending: false });
      if (status && status !== 'all') {
        if (!statuses.has(status)) {
          return json({ error: 'Invalid status' }, 400);
        }
        query = query.eq('status', status);
      }
      const { data, error } = await query.limit(250);
      if (error) throw error;
      return json({ suggestions: data ?? [] });
    }

    if (action === 'review') {
      const id = Math.trunc(Number(body.id));
      const status = stringValue(body.status, 20);
      const adminNote = stringValue(body.admin_note, 2000);
      if (!Number.isFinite(id) || id <= 0 || !statuses.has(status)) {
        return json({ error: 'Invalid review' }, 400);
      }

      const { data, error } = await serviceClient
        .from('item_suggestions')
        .update({
          status,
          admin_note: adminNote || null,
          updated_at: new Date().toISOString(),
        })
        .eq('id', id)
        .select('id')
        .maybeSingle();
      if (error) throw error;
      if (!data) return json({ error: 'Suggestion not found' }, 404);
      return json({ id, updated: true });
    }

    return json({ error: 'Unknown action' }, 400);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const status = message === 'Unauthorized'
      ? 401
      : message === 'Forbidden'
      ? 403
      : 500;
    console.error('[item-suggestions]', error);
    return json({ error: message }, status);
  }
});
