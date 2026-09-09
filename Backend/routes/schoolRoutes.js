const express = require('express');
const schoolController = require('../controllers/schoolController');
const { protect, restrictTo } = require('../middlewares/authMiddleware');
const { upload } = require('../config/cloudinary');

const router = express.Router();

// Publicly available to all authenticated users
router.use(protect);

router.get('/', schoolController.getSchoolDetails);

// Only principal can update school details
router.use(restrictTo('principal'));
router.put('/', schoolController.updateSchoolDetails);

// Dedicated logo upload
router.post('/logo', upload.single('logo'), (req, res) => {
  if (req.file) {
    res.json({ url: req.file.path });
  } else {
    res.status(400).json({ message: 'No file uploaded' });
  }
});

module.exports = router;
