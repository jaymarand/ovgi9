import { createClient } from '@supabase/supabase-js';
import type { Database } from './database.types';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient<Database>(supabaseUrl, supabaseKey, {
  auth: {
    persistSession: true,
    storageKey: 'dispatch-auth',
    storage: localStorage,
    detectSessionInUrl: false,
    flowType: 'pkce',
    autoRefreshToken: true,
  }
});

// Helper function to get user role
export const getUserRole = async () => {
  const { data: { user } } = await supabase.auth.getUser();
  return user?.user_metadata?.role;
};

// Helper function to check if user is dispatcher
export const isDispatcher = async () => {
  const role = await getUserRole();
  return role === 'dispatcher';
};

// Helper function to check if user is driver
export const isDriver = async () => {
  const role = await getUserRole();
  return role === 'driver';
};