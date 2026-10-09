const express = require('express');
const multer = require('multer');
const { requireAuth } = require('../middleware/auth');

const portalCtrl = require('../controllers/portalController');
const publicCtrl = require('../controllers/publicController');
const businessCtrl = require('../controllers/businessController');
const servicesCtrl = require('../controllers/servicesController');
const productsCtrl = require('../controllers/productsController');
const galleryCtrl = require('../controllers/galleryController');
const hoursCtrl = require('../controllers/hoursController');
const uploadCtrl = require('../controllers/uploadController');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

// ---------- Public (no login) ----------
router.post('/portal/create', portalCtrl.createFromPortal);
router.get('/public/business/:slug', publicCtrl.getBySlug);

// Image upload for portal (no auth – rate limited at /api level)
router.post('/upload', upload.single('file'), uploadCtrl.uploadImage);

// ---------- Optional authenticated APIs ----------
router.use(requireAuth);

router.get('/dashboard/stats', businessCtrl.dashboardStats);
router.get('/businesses', businessCtrl.listBusinesses);
router.post('/businesses', businessCtrl.createBusiness);
router.get('/businesses/:id', businessCtrl.getBusiness);
router.put('/businesses/:id', businessCtrl.updateBusiness);
router.delete('/businesses/:id', businessCtrl.deleteBusiness);
router.post('/businesses/:id/publish', businessCtrl.publishBusiness);
router.post('/businesses/:id/unpublish', businessCtrl.unpublishBusiness);
router.post('/businesses/:id/duplicate', businessCtrl.duplicateBusiness);

router.get('/businesses/:businessId/services', servicesCtrl.list);
router.post('/businesses/:businessId/services', servicesCtrl.create);
router.put('/services/:id', servicesCtrl.update);
router.delete('/services/:id', servicesCtrl.remove);

router.get('/businesses/:businessId/products', productsCtrl.list);
router.post('/businesses/:businessId/products', productsCtrl.create);
router.put('/products/:id', productsCtrl.update);
router.delete('/products/:id', productsCtrl.remove);

router.get('/businesses/:businessId/gallery', galleryCtrl.list);
router.post('/businesses/:businessId/gallery', galleryCtrl.create);
router.put('/gallery/:id', galleryCtrl.update);
router.delete('/gallery/:id', galleryCtrl.remove);

router.get('/businesses/:businessId/hours', hoursCtrl.list);
router.put('/businesses/:businessId/hours', hoursCtrl.upsert);

module.exports = router;
