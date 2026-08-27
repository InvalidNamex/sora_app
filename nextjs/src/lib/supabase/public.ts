import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  // We don't throw an error directly to allow build to pass without env vars,
  // but warn heavily in development.
  console.warn('Missing Supabase environment variables');
}

// Server-only anonymous client for public catalog reads
export const publicSupabase = createClient(
  supabaseUrl || 'https://placeholder.supabase.co',
  supabaseAnonKey || 'placeholder',
  {
    auth: {
      persistSession: false,
    },
  }
);
