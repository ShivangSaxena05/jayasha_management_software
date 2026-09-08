const express = require('express');
const router = express.Router();
const examController = require('../controllers/examinationController');
const { protect, restrictTo } = require('../middlewares/authMiddleware');

router.use(protect);

router.post('/', restrictTo('principal'), examController.createExam);
router.get('/', examController.getExams);
router.get('/:id/datesheet', examController.getExamDatesheet);
router.put('/:id', restrictTo('principal'), examController.updateExam);
router.delete('/:id', restrictTo('principal'), examController.deleteExam);
router.post('/marks', restrictTo('principal', 'teacher'), examController.submitMarks);
router.get('/marks', examController.getMarksByExamAndClass);
router.get('/report-card', examController.getStudentReportCard);

module.exports = router;
