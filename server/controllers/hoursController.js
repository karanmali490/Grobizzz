const { supabaseAdmin } = require('../config/supabase');

async function list(req, res, next) {
  try {
    const { businessId } = req.params;
    const { data, error } = await supabaseAdmin
      .from('business_hours')
      .select('*')
      .eq('business_id', businessId)
      .order('day_of_week');
    if (error) throw error;
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function upsert(req, res, next) {
  try {
    const { businessId } = req.params;
    const hours = Array.isArray(req.body) ? req.body : [req.body];

    // Delete existing then insert (simple full replace)
    await supabaseAdmin.from('business_hours').delete().eq('business_id', businessId);

    const rows = hours.map(h => ({
      business_id: businessId,
      day_of_week: h.day_of_week,
      is_closed: !!h.is_closed,
      open_time: h.open_time || null,
      close_time: h.close_time || null
    }));

    const { data, error } = await supabaseAdmin
      .from('business_hours')
      .insert(rows)
      .select();
    if (error) throw error;
    res.json(data);
  } catch (err) {
    next(err);
  }
}

module.exports = { list, upsert };
