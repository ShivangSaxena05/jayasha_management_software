const express = require('express');
const router = express.Router();
const { getSettings, updateSettings } = require('../controllers/schoolController');
const { protect } = require('../middlewares/authMiddleware');

router.route('/settings')
  .get(getSettings)
  .put(protect, updateSettings);

module.exports = router;
