import { createClient } from '@supabase/supabase-js';
import { auth } from '../firebase/config';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Missing public Supabase environment variables');
}

// Browser client for authenticated RLS queries
export const browserSupabase = createClient(
  supabaseUrl || 'https://placeholder.supabase.co',
  supabaseAnonKey || 'placeholder',
  {
    global: {
      fetch: async (url, options = {}) => {
        const headers = new Headers(options?.headers);
        
        const currentUser = auth.currentUser;
        if (currentUser) {
          const token = await currentUser.getIdToken();
          headers.set('Authorization', `Bearer ${token}`);
        }

        return fetch(url, {
          ...options,
          headers,
        });
      },
    },
  }
);
