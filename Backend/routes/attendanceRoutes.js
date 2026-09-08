const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');
const { protect, restrictTo } = require('../middlewares/authMiddleware');

router.use(protect);

router.post('/mark', restrictTo('principal', 'teacher'), attendanceController.markAttendance);
router.get('/class', attendanceController.getAttendanceByClass);
router.get('/report', attendanceController.getStudentAttendanceReport);

module.exports = router;
