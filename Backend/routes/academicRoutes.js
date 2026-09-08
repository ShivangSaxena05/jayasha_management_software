const express = require('express');
const router = express.Router();
const { saveAcademicSession, getAcademicSessions, getActiveSession } = require('../controllers/academicController');
const { protect } = require('../middlewares/authMiddleware');

router.route('/').post(protect, saveAcademicSession).get(protect, getAcademicSessions);
router.route('/active').get(protect, getActiveSession);

module.exports = router;
