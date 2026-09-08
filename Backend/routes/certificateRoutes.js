const express = require('express');
const router = express.Router();
const {
  generateCertificate,
  getRecentCertificates,
} = require('../controllers/certificateController');
const { protect } = require('../middlewares/authMiddleware');

router.post('/', protect, generateCertificate);
router.get('/recent', protect, getRecentCertificates);

module.exports = router;
