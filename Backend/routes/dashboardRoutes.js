const mongoose = require('mongoose');
const express = require('express');
const router = express.Router();
const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const Class = require('../models/Class');
const FeeStructure = require('../models/FeeStructure');
const FeePayment = require('../models/FeePayment');
const AcademicSession = require('../models/AcademicSession');
const { protect } = require('../middlewares/authMiddleware');

router.get('/stats', protect, async (req, res) => {
  try {
    // 1. Fetch Active Session first as it's the anchor for all stats
    const activeSession = await AcademicSession.findOne({ isActive: true });

    // Global counts
    const teacherCount = await Teacher.countDocuments({ status: 'active' });
    const classCount = await Class.countDocuments();

    if (!activeSession) {
      return res.json({
        success: true,
        data: {
          counts: {
            students: 0,
            teachers: teacherCount,
            classes: classCount,
            totalCollection: 0,
            expectedCollection: 0,
            pendingFeesCount: 0
          },
          recentStudents: [],
        }
      });
    }

    // 2. Aggregate Data for Active Session
    const activeStudents = await Student.find({
      status: 'active',
      academicSession: activeSession._id
    }).populate('currentClass');

    const studentCount = activeStudents.length;

    // Actual Payments in this session
    const payments = await FeePayment.find({ academicSession: activeSession._id });
    const totalCollection = payments.reduce((sum, p) => sum + p.amount, 0);

    // Fee Structures for projection
    const feeStructures = await FeeStructure.find({ academicSession: activeSession._id });
    const feeMap = new Map();
    feeStructures.forEach(fs => {
      feeMap.set(fs.class.toString(), fs.components);
    });

    let expectedCollection = 0;
    activeStudents.forEach(student => {
      if (student.currentClass) {
        const components = feeMap.get(student.currentClass._id.toString());
        if (components) {
          components.forEach(comp => {
            if (comp.frequency === 'monthly') {
              expectedCollection += (comp.amount * 12);
            } else {
              expectedCollection += comp.amount;
            }
          });
        }
      }
    });

    // 3. Financial Health (Pending Fees)
    const paidStudentIds = await FeePayment.distinct('student', { academicSession: activeSession._id });
    const pendingFeesCount = Math.max(0, studentCount - paidStudentIds.length);

    const recentStudents = await Student.find({ academicSession: activeSession._id })
      .sort({ createdAt: -1 })
      .limit(5)
      .populate('currentClass', 'name');

    // 5. Staff Salaries (Total Paid this month)
    const currentMonth = new Date().getMonth() + 1;
    const currentYear = new Date().getFullYear();
    const salaryStats = await mongoose.model('SalaryRecord').aggregate([
      { $match: { month: currentMonth, year: currentYear } },
      { $group: { _id: null, totalPaid: { $sum: '$netSalary' } } }
    ]);
    const monthlySalaryExpense = salaryStats.length > 0 ? salaryStats[0].totalPaid : 0;

    res.json({
      success: true,
      data: {
        counts: {
          students: studentCount,
          teachers: teacherCount,
          classes: classCount,
          totalCollection,
          expectedCollection,
          pendingFeesCount,
          monthlySalaryExpense
        },
        recentStudents,
      }
    });
  } catch (error) {
    console.error('Dashboard Stats Error:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error',
      error: error.message
    });
  }
});

module.exports = router;
