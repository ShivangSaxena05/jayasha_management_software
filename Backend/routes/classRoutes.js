const express = require('express');
const router = express.Router();
const { saveClasses, getClasses, addClass, updateClass } = require('../controllers/classController');
const { protect } = require('../middlewares/authMiddleware');

router.route('/').post(protect, saveClasses).get(protect, getClasses);
router.route('/add').post(protect, addClass);
router.route('/:id').put(protect, updateClass);

module.exports = router;
