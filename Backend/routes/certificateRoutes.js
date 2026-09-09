const express = require('express');
const router = express.Router();
const {
  generateCertificate,
  getRecentCertificates,
  updateCertificate,
} = require('../controllers/certificateController');
const { protect } = require('../middlewares/authMiddleware');

router.post('/', protect, generateCertificate);
router.get('/recent', protect, getRecentCertificates);
router.put('/:id', protect, updateCertificate);

module.exports = router;
