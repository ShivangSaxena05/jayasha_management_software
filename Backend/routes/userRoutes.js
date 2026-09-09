const express = require('express');
const router = express.Router();
const {
  checkSetup,
  setupPrincipal,
  loginWithPin,
  getProfile,
  updateProfile,
} = require('../controllers/userController');

const { protect } = require('../middlewares/authMiddleware');

router.get('/check-setup', checkSetup);
router.post('/setup', setupPrincipal);
router.post('/pin-login', loginWithPin);
router.route('/profile')
  .get(protect, getProfile)
  .put(protect, updateProfile);

module.exports = router;
