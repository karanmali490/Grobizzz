/**
 * Unique slug generation for business public URLs
 */
const slugify = require('slugify');
const { supabaseAdmin } = require('../config/supabase');

async function generateUniqueSlug(name, excludeId = null) {
  let base = slugify(name, { lower: true, strict: true, remove: /[*+~.()'"!:@]/g });
  if (!base) base = 'business';

  let candidate = base;
  let counter = 1;

  while (true) {
    let query = supabaseAdmin
      .from('businesses')
      .select('id')
      .eq('slug', candidate)
      .limit(1);

    if (excludeId) {
      query = query.neq('id', excludeId);
    }

    const { data, error } = await query;
    if (error) throw error;

    if (!data || data.length === 0) {
      return candidate;
    }

    counter += 1;
    candidate = `${base}-${counter}`;
  }
}

module.exports = { generateUniqueSlug };
