/**
 * Single Portal endpoint
 * Form submits here → backend creates business, generates slug, publishes, returns public URL
 */
const { supabaseAdmin } = require('../config/supabase');
const { generateUniqueSlug } = require('../utils/slug');

async function createFromPortal(req, res, next) {
  try {
    const body = req.body || {};

    if (!body.business_name || !body.category) {
      return res.status(400).json({ error: 'Business name and category are required' });
    }

    const slug = await generateUniqueSlug(body.business_name);
    const shouldPublish = body.publish !== false;

    // Resolve template by slug (modern | restaurant | service)
    let templateId = body.template_id || null;
    if (!templateId && body.template_slug) {
      const { data: tpl } = await supabaseAdmin
        .from('templates')
        .select('id')
        .eq('slug', body.template_slug)
        .maybeSingle();
      if (tpl) templateId = tpl.id;
    }

    const payload = {
      business_name: body.business_name,
      slug,
      category: body.category,
      subcategory: body.subcategory || null,
      tagline: body.tagline || null,
      description: body.description || body.about || null,
      about: body.about || null,
      year_established: body.year_established || null,
      phone: body.phone || null,
      alternate_phone: body.alternate_phone || null,
      whatsapp: body.whatsapp || body.phone || null,
      email: body.email || null,
      website: body.website || null,
      address: body.address || null,
      area: body.area || null,
      city: body.city || null,
      state: body.state || null,
      pincode: body.pincode || null,
      latitude: body.latitude || null,
      longitude: body.longitude || null,
      google_maps_url: body.google_maps_url || null,
      google_business_url: body.google_business_url || null,
      instagram_url: body.instagram_url || null,
      facebook_url: body.facebook_url || null,
      youtube_url: body.youtube_url || null,
      linkedin_url: body.linkedin_url || null,
      twitter_url: body.twitter_url || null,
      zomato_url: body.zomato_url || null,
      swiggy_url: body.swiggy_url || null,
      other_links: body.other_links || [],
      primary_color: body.primary_color || '#c97b3a',
      secondary_color: body.secondary_color || '#1a1a1a',
      accent_color: body.accent_color || '#f5f0e8',
      template_id: templateId,
      features: body.features || {
        whatsapp: true,
        call: true,
        maps: true,
        share: true,
        gallery: true,
        services: true,
        menu: true,
        reviews: true,
        social: true
      },
      seo_title: body.seo_title || null,
      seo_description: body.seo_description || null,
      seo_keywords: body.seo_keywords || null,
      logo_url: body.logo_url || null,
      cover_image_url: body.cover_image_url || null,
      favicon_url: body.favicon_url || null,
      status: shouldPublish ? 'published' : 'draft',
      published_at: shouldPublish ? new Date().toISOString() : null
    };

    const { data: business, error } = await supabaseAdmin
      .from('businesses')
      .insert(payload)
      .select()
      .single();

    if (error) throw error;

    // Opening hours
    if (Array.isArray(body.hours) && body.hours.length) {
      const rows = body.hours.map(h => ({
        business_id: business.id,
        day_of_week: h.day_of_week,
        is_closed: !!h.is_closed,
        open_time: h.open_time || null,
        close_time: h.close_time || null
      }));
      await supabaseAdmin.from('business_hours').insert(rows);
    }

    // Featured items → products
    if (Array.isArray(body.featured_items) && body.featured_items.length) {
      const products = body.featured_items.map((name, i) => ({
        business_id: business.id,
        name,
        display_order: i,
        is_available: true
      }));
      await supabaseAdmin.from('products').insert(products);
    }

    // Services
    if (Array.isArray(body.services) && body.services.length) {
      const services = body.services.map((s, i) => ({
        business_id: business.id,
        name: s.name,
        description: s.description || null,
        price: s.price != null ? s.price : null,
        price_label: s.price_label || null,
        category: s.category || null,
        display_order: i,
        is_active: true
      }));
      await supabaseAdmin.from('services').insert(services);
    }

    // Gallery image URLs (already uploaded)
    if (Array.isArray(body.gallery_urls) && body.gallery_urls.length) {
      const galleryRows = body.gallery_urls
        .filter(Boolean)
        .map((url, i) => ({
          business_id: business.id,
          image_url: url,
          display_order: i
        }));
      if (galleryRows.length) {
        await supabaseAdmin.from('gallery').insert(galleryRows);
      }
    }

    const profile_url = `/p/${business.slug}`;

    res.status(201).json({
      id: business.id,
      business_name: business.business_name,
      slug: business.slug,
      status: business.status,
      profile_url,
      logo_url: business.logo_url,
      cover_image_url: business.cover_image_url
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { createFromPortal };
