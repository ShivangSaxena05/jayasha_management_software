const express = require('express');
const router = express.Router();
const {
  registerAdmission,
  getStudents,
  getStudentById,
  updateStudent,
  sendMessageToClass,
} = require('../controllers/studentController');
const { protect } = require('../middlewares/authMiddleware');

router.post('/admission', protect, registerAdmission);
router.post('/send-message', protect, sendMessageToClass);
router.get('/', protect, getStudents);
router.get('/:id', protect, getStudentById);
router.put('/:id', protect, updateStudent);

module.exports = router;
