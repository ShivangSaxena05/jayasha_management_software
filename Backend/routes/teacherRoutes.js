const express = require('express');
const router = express.Router();
const {
  saveTeachers,
  getTeachers,
  addTeacher,
  updateTeacher,
  deleteTeacher,
  addSalaryRecord,
  getSalaryRecords,
  applyLeave,
  getLeaveRecords,
  updateLeaveStatus
} = require('../controllers/teacherController');
const { protect } = require('../middlewares/authMiddleware');

router.route('/')
  .post(protect, saveTeachers)
  .get(protect, getTeachers);

router.route('/add')
  .post(protect, addTeacher);

router.route('/leaves/:leaveId')
  .put(protect, updateLeaveStatus);

router.route('/:id')
  .put(protect, updateTeacher)
  .delete(protect, deleteTeacher);

router.route('/:id/salary')
  .post(protect, addSalaryRecord)
  .get(protect, getSalaryRecords);

router.route('/:id/leaves')
  .post(protect, applyLeave)
  .get(protect, getLeaveRecords);

module.exports = router;
