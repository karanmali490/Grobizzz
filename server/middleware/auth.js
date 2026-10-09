/**
 * Authentication middleware using Supabase JWT
 */
const { supabase, supabaseAdmin } = require('../config/supabase');

async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;

    if (!token) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    // Load profile for role
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();

    req.user = user;
    req.profile = profile || { id: user.id, role: 'business_owner' };
    next();
  } catch (err) {
    console.error('[auth]', err);
    return res.status(401).json({ error: 'Authentication failed' });
  }
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.profile || !roles.includes(req.profile.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    next();
  };
}

module.exports = { requireAuth, requireRole };
