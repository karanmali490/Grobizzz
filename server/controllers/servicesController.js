const { supabaseAdmin } = require('../config/supabase');

async function list(req, res, next) {
  try {
    const { businessId } = req.params;
    const { data, error } = await supabaseAdmin
      .from('services')
      .select('*')
      .eq('business_id', businessId)
      .order('display_order');
    if (error) throw error;
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const { businessId } = req.params;
    const payload = { ...req.body, business_id: businessId };
    const { data, error } = await supabaseAdmin
      .from('services')
      .insert(payload)
      .select()
      .single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const { id } = req.params;
    const { data, error } = await supabaseAdmin
      .from('services')
      .update(req.body)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    const { id } = req.params;
    const { error } = await supabaseAdmin.from('services').delete().eq('id', id);
    if (error) throw error;
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}

module.exports = { list, create, update, remove };
