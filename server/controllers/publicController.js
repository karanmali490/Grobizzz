/**
 * Public profile API – no auth required
 * Only returns published businesses
 */
const { supabaseAdmin } = require('../config/supabase');

async function getBySlug(req, res, next) {
  try {
    const { slug } = req.params;

    const { data: business, error } = await supabaseAdmin
      .from('businesses')
      .select(`
        *,
        templates:template_id ( slug, name, folder )
      `)
      .eq('slug', slug)
      .eq('status', 'published')
      .single();

    if (error || !business) {
      return res.status(404).json({ error: 'Business profile not found' });
    }

    const [services, products, gallery, hours] = await Promise.all([
      supabaseAdmin
        .from('services')
        .select('*')
        .eq('business_id', business.id)
        .eq('is_active', true)
        .order('display_order'),
      supabaseAdmin
        .from('products')
        .select('*')
        .eq('business_id', business.id)
        .eq('is_available', true)
        .order('display_order'),
      supabaseAdmin
        .from('gallery')
        .select('*')
        .eq('business_id', business.id)
        .order('display_order'),
      supabaseAdmin
        .from('business_hours')
        .select('*')
        .eq('business_id', business.id)
        .order('day_of_week')
    ]);

    // Strip internal fields if needed
    const { owner_id, ...publicBusiness } = business;

    res.json({
      ...publicBusiness,
      services: services.data || [],
      products: products.data || [],
      gallery: gallery.data || [],
      hours: hours.data || []
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { getBySlug };
