/**
 * Central error handler – never leak raw errors to clients
 */
function errorHandler(err, req, res, next) {
  console.error('[ERROR]', err.message || err);

  if (err.code === '23505') {
    // unique_violation
    return res.status(409).json({ error: 'A record with this value already exists.' });
  }

  if (err.status) {
    return res.status(err.status).json({ error: err.message || 'Request failed' });
  }

  res.status(500).json({
    error: 'Something went wrong. Please try again.'
  });
}

module.exports = { errorHandler };
