import { createClient } from 'jsr:@supabase/supabase-js@2';
import { initializeApp, cert, getApps } from 'npm:firebase-admin/app';
import { getAuth } from 'npm:firebase-admin/auth';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const messageTypes = new Set(['card', 'modal', 'image', 'banner']);
const platforms = new Set(['all', 'android', 'ios', 'web']);
const languages = new Set(['all', 'en', 'ar']);
const imageExtensions = new Set(['jpg', 'jpeg', 'png', 'webp']);
const hexColor = /^#[0-9A-Fa-f]{6}$/;

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

async function requireAdmin(
  serviceClient: ReturnType<typeof createClient>,
  authHeader: string,
) {
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) throw new Error('Unauthorized');

  const decoded = await getAuth().verifyIdToken(token);
  const { data, error } = await serviceClient
    .from('users')
    .select('isAdmin')
    .eq('uid', decoded.uid)
    .maybeSingle();
  if (error || data?.isAdmin !== true) throw new Error('Forbidden');
  return decoded.uid;
}

function stringValue(value: unknown, maxLength: number): string {
  if (typeof value !== 'string') return '';
  return value.trim().slice(0, maxLength);
}

function isValidTarget(value: string): boolean {
  if (!value) return true;
  if (value.startsWith('/')) return value.length > 1;
  try {
    const url = new URL(value);
    return url.protocol === 'sora:' ||
      ((url.protocol === 'http:' || url.protocol === 'https:') &&
        url.hostname.length > 0);
  } catch {
    return false;
  }
}

function isValidWebUrl(value: string): boolean {
  if (!value) return true;
  try {
    const url = new URL(value);
    return (url.protocol === 'http:' || url.protocol === 'https:') &&
      url.hostname.length > 0;
  } catch {
    return false;
  }
}

function parseMessage(raw: Record<string, unknown>, createdBy: string) {
  const type = stringValue(raw.type, 20);
  const title = stringValue(raw.title, 120);
  const body = stringValue(raw.body, 1000);
  const imageUrl = stringValue(raw.image_url, 2000);
  const primaryActionUrl = stringValue(raw.primary_action_url, 2000);
  const secondaryActionUrl = stringValue(raw.secondary_action_url, 2000);
  const targetPlatform = stringValue(raw.target_platform, 20) || 'all';
  const targetLanguage = stringValue(raw.target_language, 10) || 'all';

  if (!messageTypes.has(type)) throw new Error('Invalid message type');
  if (type === 'image' && !imageUrl) {
    throw new Error('Image messages require an image');
  }
  if (type !== 'image' && !title && !body) {
    throw new Error('A title or body is required');
  }
  if (!isValidWebUrl(imageUrl)) throw new Error('Invalid image URL');
  if (!isValidTarget(primaryActionUrl) ||
    !isValidTarget(secondaryActionUrl)) {
    throw new Error('Invalid action URL');
  }
  if (!platforms.has(targetPlatform)) throw new Error('Invalid platform');
  if (!languages.has(targetLanguage)) throw new Error('Invalid language');

  const colors = {
    background_color: stringValue(raw.background_color, 7).toUpperCase(),
    text_color: stringValue(raw.text_color, 7).toUpperCase(),
    button_color: stringValue(raw.button_color, 7).toUpperCase(),
    button_text_color: stringValue(raw.button_text_color, 7).toUpperCase(),
  };
  if (Object.values(colors).some((color) => !hexColor.test(color))) {
    throw new Error('Invalid color');
  }

  const startsAt = new Date(String(raw.starts_at ?? ''));
  const endsAt = raw.ends_at == null ? null : new Date(String(raw.ends_at));
  if (Number.isNaN(startsAt.getTime()) ||
    (endsAt && Number.isNaN(endsAt.getTime()))) {
    throw new Error('Invalid campaign dates');
  }
  if (endsAt && endsAt <= startsAt) throw new Error('Invalid expiry date');

  return {
    type,
    title,
    body,
    image_url: imageUrl,
    ...colors,
    primary_button_text: stringValue(raw.primary_button_text, 60),
    primary_action_url: primaryActionUrl,
    secondary_button_text: type === 'card'
      ? stringValue(raw.secondary_button_text, 60)
      : '',
    secondary_action_url: type === 'card' ? secondaryActionUrl : '',
    target_platform: targetPlatform,
    target_language: targetLanguage,
    display_once: raw.display_once !== false,
    starts_at: startsAt.toISOString(),
    ends_at: endsAt?.toISOString() ?? null,
    created_by: createdBy,
  };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  try {
    initFirebaseAdmin();
    const serviceClient = createClient(
      getEnv('SUPABASE_URL'),
      getEnv('SUPABASE_SERVICE_ROLE_KEY', 'SERVICE_ROLE_KEY'),
    );
    const uid = await requireAdmin(
      serviceClient,
      req.headers.get('Authorization') ?? '',
    );
    const body = await req.json() as Record<string, unknown>;
    const action = body.action;

    if (action === 'create_upload') {
      const extension = stringValue(body.extension, 5).toLowerCase();
      if (!imageExtensions.has(extension)) {
        return json({ error: 'Unsupported image type' }, 400);
      }

      const path = `campaigns/${crypto.randomUUID()}.${extension}`;
      const { data, error } = await serviceClient.storage
        .from('in_app_messages')
        .createSignedUploadUrl(path);
      if (error || !data) throw error ?? new Error('Could not sign upload');

      return json({
        path,
        token: data.token,
        publicUrl: serviceClient.storage
          .from('in_app_messages')
          .getPublicUrl(path).data.publicUrl,
      });
    }

    if (action === 'publish') {
      const rawMessage = body.message;
      if (!rawMessage || typeof rawMessage !== 'object') {
        return json({ error: 'Message payload is required' }, 400);
      }

      const message = parseMessage(
        rawMessage as Record<string, unknown>,
        uid,
      );
      const { data, error } = await serviceClient
        .from('in_app_messages')
        .insert(message)
        .select('id')
        .single();
      if (error) throw error;
      return json({ id: data.id, published: true });
    }

    return json({ error: 'Unknown action' }, 400);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const status = message === 'Unauthorized'
      ? 401
      : message === 'Forbidden'
      ? 403
      : 500;
    console.error('[manage-in-app-messages]', error);
    return json({ error: message }, status);
  }
});
