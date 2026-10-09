/**
 * Business CRUD + publish / unpublish / duplicate
 */
const { supabaseAdmin } = require('../config/supabase');
const { generateUniqueSlug } = require('../utils/slug');

async function listBusinesses(req, res, next) {
  try {
    const { search, category, city, status, page = 1, limit = 20 } = req.query;
    let query = supabaseAdmin
      .from('businesses')
      .select('id, business_name, slug, category, city, status, verified, template_id, created_at, logo_url', { count: 'exact' })
      .order('created_at', { ascending: false });

    // Role-based filter
    if (req.profile.role === 'business_owner') {
      query = query.eq('owner_id', req.user.id);
    }

    if (search) query = query.ilike('business_name', `%${search}%`);
    if (category) query = query.eq('category', category);
    if (city) query = query.ilike('city', `%${city}%`);
    if (status) query = query.eq('status', status);

    const from = (Number(page) - 1) * Number(limit);
    const to = from + Number(limit) - 1;
    query = query.range(from, to);

    const { data, error, count } = await query;
    if (error) throw error;

    res.json({ data, total: count, page: Number(page), limit: Number(limit) });
  } catch (err) {
    next(err);
  }
}

async function getBusiness(req, res, next) {
  try {
    const { id } = req.params;
    const { data: business, error } = await supabaseAdmin
      .from('businesses')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !business) {
      return res.status(404).json({ error: 'Business not found' });
    }

    // Ownership check for non-admins
    if (req.profile.role === 'business_owner' && business.owner_id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const [services, products, gallery, hours] = await Promise.all([
      supabaseAdmin.from('services').select('*').eq('business_id', id).order('display_order'),
      supabaseAdmin.from('products').select('*').eq('business_id', id).order('display_order'),
      supabaseAdmin.from('gallery').select('*').eq('business_id', id).order('display_order'),
      supabaseAdmin.from('business_hours').select('*').eq('business_id', id).order('day_of_week')
    ]);

    res.json({
      ...business,
      services: services.data || [],
      products: products.data || [],
      gallery: gallery.data || [],
      hours: hours.data || []
    });
  } catch (err) {
    next(err);
  }
}

async function createBusiness(req, res, next) {
  try {
    const body = req.body;
    if (!body.business_name || !body.category) {
      return res.status(400).json({ error: 'Business name and category are required' });
    }

    const slug = await generateUniqueSlug(body.business_name);

    const payload = {
      owner_id: req.user.id,
      business_name: body.business_name,
      slug,
      category: body.category,
      subcategory: body.subcategory || null,
      tagline: body.tagline || null,
      description: body.description || null,
      about: body.about || null,
      year_established: body.year_established || null,
      phone: body.phone || null,
      alternate_phone: body.alternate_phone || null,
      whatsapp: body.whatsapp || null,
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
      template_id: body.template_id || null,
      features: body.features || undefined,
      seo_title: body.seo_title || null,
      seo_description: body.seo_description || null,
      seo_keywords: body.seo_keywords || null,
      logo_url: body.logo_url || null,
      cover_image_url: body.cover_image_url || null,
      status: 'draft'
    };

    const { data, error } = await supabaseAdmin
      .from('businesses')
      .insert(payload)
      .select()
      .single();

    if (error) throw error;

    // Optional nested data
    if (Array.isArray(body.hours) && body.hours.length) {
      const hoursRows = body.hours.map(h => ({
        business_id: data.id,
        day_of_week: h.day_of_week,
        is_closed: !!h.is_closed,
        open_time: h.open_time || null,
        close_time: h.close_time || null
      }));
      await supabaseAdmin.from('business_hours').insert(hoursRows);
    }

    res.status(201).json(data);
  } catch (err) {
    next(err);
  }
}

async function updateBusiness(req, res, next) {
  try {
    const { id } = req.params;
    const body = req.body;

    // Ownership
    const { data: existing } = await supabaseAdmin
      .from('businesses')
      .select('owner_id, business_name, slug')
      .eq('id', id)
      .single();

    if (!existing) return res.status(404).json({ error: 'Business not found' });
    if (req.profile.role === 'business_owner' && existing.owner_id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const updates = { ...body };
    delete updates.id;
    delete updates.owner_id;
    delete updates.created_at;
    delete updates.services;
    delete updates.products;
    delete updates.gallery;
    delete updates.hours;

    // Regenerate slug only if name changed
    if (body.business_name && body.business_name !== existing.business_name) {
      updates.slug = await generateUniqueSlug(body.business_name, id);
    }

    const { data, error } = await supabaseAdmin
      .from('businesses')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function deleteBusiness(req, res, next) {
  try {
    const { id } = req.params;
    const { data: existing } = await supabaseAdmin
      .from('businesses')
      .select('owner_id')
      .eq('id', id)
      .single();

    if (!existing) return res.status(404).json({ error: 'Business not found' });
    if (req.profile.role !== 'admin' && existing.owner_id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Soft-delete by status preferred, but hard delete for now (cascade handles children)
    const { error } = await supabaseAdmin.from('businesses').delete().eq('id', id);
    if (error) throw error;
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}

async function publishBusiness(req, res, next) {
  try {
    const { id } = req.params;
    const { data, error } = await supabaseAdmin
      .from('businesses')
      .update({ status: 'published', published_at: new Date().toISOString() })
      .eq('id', id)
      .select('id, slug, status')
      .single();
    if (error) throw error;
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function unpublishBusiness(req, res, next) {
  try {
    const { id } = req.params;
    const { data, error } = await supabaseAdmin
      .from('businesses')
      .update({ status: 'unpublished' })
      .eq('id', id)
      .select('id, slug, status')
      .single();
    if (error) throw error;
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function duplicateBusiness(req, res, next) {
  try {
    const { id } = req.params;
    const { data: src, error } = await supabaseAdmin
      .from('businesses')
      .select('*')
      .eq('id', id)
      .single();
    if (error || !src) return res.status(404).json({ error: 'Business not found' });

    const newSlug = await generateUniqueSlug(src.business_name + ' Copy');
    const { id: _old, created_at, updated_at, published_at, ...rest } = src;

    const { data: copy, error: insertErr } = await supabaseAdmin
      .from('businesses')
      .insert({
        ...rest,
        owner_id: req.user.id,
        slug: newSlug,
        business_name: src.business_name + ' (Copy)',
        status: 'draft',
        published_at: null,
        verified: false
      })
      .select()
      .single();
    if (insertErr) throw insertErr;

    // Copy children
    const [svc, prod, gal, hrs] = await Promise.all([
      supabaseAdmin.from('services').select('*').eq('business_id', id),
      supabaseAdmin.from('products').select('*').eq('business_id', id),
      supabaseAdmin.from('gallery').select('*').eq('business_id', id),
      supabaseAdmin.from('business_hours').select('*').eq('business_id', id)
    ]);

    const mapRows = (rows, extra = {}) =>
      (rows.data || []).map(({ id: _i, created_at: _c, updated_at: _u, ...r }) => ({
        ...r,
        business_id: copy.id,
        ...extra
      }));

    if (svc.data?.length) await supabaseAdmin.from('services').insert(mapRows(svc));
    if (prod.data?.length) await supabaseAdmin.from('products').insert(mapRows(prod));
    if (gal.data?.length) await supabaseAdmin.from('gallery').insert(mapRows(gal));
    if (hrs.data?.length) await supabaseAdmin.from('business_hours').insert(mapRows(hrs));

    res.status(201).json(copy);
  } catch (err) {
    next(err);
  }
}

async function dashboardStats(req, res, next) {
  try {
    let base = supabaseAdmin.from('businesses').select('status, verified', { count: 'exact' });
    if (req.profile.role === 'business_owner') {
      base = base.eq('owner_id', req.user.id);
    }
    const { data, error, count } = await base;
    if (error) throw error;

    const stats = {
      total: count || 0,
      published: (data || []).filter(b => b.status === 'published').length,
      draft: (data || []).filter(b => b.status === 'draft').length,
      unpublished: (data || []).filter(b => b.status === 'unpublished').length,
      verified: (data || []).filter(b => b.verified).length
    };
    res.json(stats);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  listBusinesses,
  getBusiness,
  createBusiness,
  updateBusiness,
  deleteBusiness,
  publishBusiness,
  unpublishBusiness,
  duplicateBusiness,
  dashboardStats
};
