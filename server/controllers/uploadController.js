/**
 * Image upload to Supabase Storage
 * Buckets: business-logos, business-covers, business-gallery, business-products, business-services
 */
const { supabaseAdmin } = require('../config/supabase');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const ALLOWED = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/svg+xml'
];
const MAX_SIZE = 5 * 1024 * 1024; // 5 MB

async function uploadImage(req, res, next) {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    if (!ALLOWED.includes(req.file.mimetype)) {
      return res.status(400).json({ error: 'Only JPG, PNG, WEBP and SVG images are allowed' });
    }

    if (req.file.size > MAX_SIZE) {
      return res.status(400).json({ error: 'Image must be under 5 MB' });
    }

    const bucket = req.body.bucket || req.query.bucket || 'business-gallery';
    const validBuckets = [
      'business-logos',
      'business-covers',
      'business-gallery',
      'business-products',
      'business-services'
    ];
    if (!validBuckets.includes(bucket)) {
      return res.status(400).json({ error: 'Invalid storage bucket' });
    }

    const extMap = {
      'image/jpeg': '.jpg',
      'image/jpg': '.jpg',
      'image/png': '.png',
      'image/webp': '.webp',
      'image/svg+xml': '.svg'
    };
    const ext = extMap[req.file.mimetype] || path.extname(req.file.originalname).toLowerCase() || '.jpg';
    const filename = uuidv4() + ext;

    const { data, error } = await supabaseAdmin.storage
      .from(bucket)
      .upload(filename, req.file.buffer, {
        contentType: req.file.mimetype,
        upsert: false
      });

    if (error) {
      console.error('[upload]', error);
      const msg = (error.message || '').toLowerCase();
      if (msg.includes('bucket') || msg.includes('not found')) {
        return res.status(500).json({
          error: 'Storage bucket missing. Create public buckets: business-logos, business-covers, business-gallery in Supabase Storage.'
        });
      }
      return res.status(500).json({ error: 'Image upload failed. Please try again.' });
    }

    const { data: publicUrl } = supabaseAdmin.storage
      .from(bucket)
      .getPublicUrl(filename);

    res.json({
      url: publicUrl.publicUrl,
      path: data.path,
      bucket
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { uploadImage };
