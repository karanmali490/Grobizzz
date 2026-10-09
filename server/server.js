/**
 * GROBizzz – Single Portal + Backend
 *
 * Frontend: one form portal
 * Backend: create business, generate slug, publish, serve public profile
 */
require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { errorHandler } = require('./middleware/errorHandler');
const apiRoutes = require('./routes');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false
}));
app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false
});
app.use('/api', limiter);

app.use('/api', apiRoutes);

const clientRoot = path.join(__dirname, '..', 'client');
app.use('/portal', express.static(path.join(clientRoot, 'portal')));
app.use('/public', express.static(path.join(clientRoot, 'public')));
app.use('/assets', express.static(path.join(clientRoot, 'assets')));
app.use('/templates', express.static(path.join(__dirname, '..', 'templates')));

// Single portal (the form)
app.get('/', (req, res) => {
  res.sendFile(path.join(clientRoot, 'portal', 'index.html'));
});
app.get('/portal', (req, res) => {
  res.sendFile(path.join(clientRoot, 'portal', 'index.html'));
});

// Public profile by slug
app.get('/p/:slug', (req, res) => {
  res.sendFile(path.join(clientRoot, 'public', 'profile.html'));
});

app.get('/health', (req, res) => res.json({ status: 'ok', service: 'grobizzz' }));

app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.use(errorHandler);

app.listen(PORT, () => {
  console.log('GROBizzz running on http://localhost:' + PORT);
  console.log('  Portal (form):  http://localhost:' + PORT + '/');
  console.log('  Public profile: http://localhost:' + PORT + '/p/:slug');
});
