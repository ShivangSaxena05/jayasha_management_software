const express = require('express');
const router = express.Router();
const { upload } = require('../config/cloudinary');

// @desc    Upload multiple files for onboarding
// @route   POST /api/upload/onboarding
// @access  Public (During setup)
router.post('/onboarding', upload.fields([
  { name: 'principal_photo', maxCount: 1 },
  { name: 'principal_aadhaar_front', maxCount: 1 },
  { name: 'principal_aadhaar_back', maxCount: 1 }
]), (req, res) => {
  try {
    const files = req.files;
    const urls = {};

    if (files['principal_photo']) {
      urls.photoUrl = files['principal_photo'][0].path;
    }
    if (files['principal_aadhaar_front']) {
      urls.aadhaarFrontUrl = files['principal_aadhaar_front'][0].path;
    }
    if (files['principal_aadhaar_back']) {
      urls.aadhaarBackUrl = files['principal_aadhaar_back'][0].path;
    }

    res.json(urls);
  } catch (error) {
    res.status(500).json({ message: 'Upload failed', error: error.message });
  }
});

// @desc    General teacher/staff/student photo upload
// @route   POST /api/upload/photo
// @access  Private
router.post('/photo', upload.single('photo'), (req, res) => {
  if (req.file) {
    res.json({ url: req.file.path });
  } else {
    res.status(400).json({ message: 'No file uploaded' });
  }
});

module.exports = router;
