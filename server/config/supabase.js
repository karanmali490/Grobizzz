/**
 * Supabase client configuration
 * Service-role client is used only on the server.
 * Never expose SUPABASE_SERVICE_ROLE_KEY to the browser.
 */
require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('[GROBizzz] SUPABASE_URL or SUPABASE_ANON_KEY missing. API will fail until configured.');
}

// Public client (respects RLS)
const supabase = createClient(supabaseUrl || '', supabaseAnonKey || '');

// Admin client (bypasses RLS) – server only
const supabaseAdmin = createClient(
  supabaseUrl || '',
  supabaseServiceKey || supabaseAnonKey || '',
  { auth: { autoRefreshToken: false, persistSession: false } }
);

module.exports = { supabase, supabaseAdmin };
