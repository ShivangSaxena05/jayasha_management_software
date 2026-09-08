const mongoose = require('mongoose');
const FeeStructure = require('../models/FeeStructure');
const FeePayment = require('../models/FeePayment');
const Student = require('../models/Student');
const { sendSMS } = require('../utils/smsService');

// @desc    Save Fee Structure for classes
// @route   POST /api/fees/structure
// @access  Private/Principal
const saveFeeStructure = async (req, res) => {
  const { fees } = req.body; // Expects array of { academicSessionId, classId, components: [...] }
  try {
    const operations = fees.map(f => ({
      updateOne: {
        filter: { academicSession: f.academicSessionId, class: f.classId },
        update: { $set: { components: f.components } },
        upsert: true
      }
    }));

    await FeeStructure.bulkWrite(operations);
    res.status(201).json({ message: 'Fee structures saved successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all Fee Structures
// @route   GET /api/fees/structure
// @access  Private
const getFeeStructures = async (req, res) => {
  try {
    const fees = await FeeStructure.find({}).populate('class academicSession');
    res.json(fees);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Record a fee payment
// @route   POST /api/fees/payments
// @access  Private
const recordPayment = async (req, res) => {
  const { studentId, academicSessionId, amount, paymentMode, category, remarks } = req.body;

  try {
    const payment = await FeePayment.create({
      student: studentId,
      academicSession: academicSessionId,
      amount,
      paymentMode,
      category,
      remarks,
      receivedBy: req.user._id
    });

    if (payment) {
      // Send Payment Confirmation SMS
      const student = await Student.findById(studentId);
      if (student) {
        const message = `Payment Received: ₹${amount} for ${category} fee of ${student.name}. Mode: ${paymentMode}. Thank you, Jayasha Children's Academy.`;
        sendSMS(student.guardianPhone, message);
      }
    }

    res.status(201).json(payment);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get student fee status (Total due vs Paid)
// @route   GET /api/fees/student/:id
// @access  Private
const getStudentFeeStatus = async (req, res) => {
  try {
    const student = await Student.findById(req.params.id).populate('currentClass academicSession');
    if (!student) {
      return res.status(404).json({ message: 'Student not found' });
    }

    // Get structure for this student's class and session
    const structure = await FeeStructure.findOne({
      class: student.currentClass._id,
      academicSession: student.academicSession._id
    });

    // Get all payments made by this student in this session
    const payments = await FeePayment.find({
      student: student._id,
      academicSession: student.academicSession._id
    });

    const totalPaid = payments.reduce((sum, p) => sum + p.amount, 0);

    // Calculate total due from structure
    // (Note: This is a simplified calculation; real logic might depend on admission date, frequency etc.)
    const totalPayable = structure ? structure.components.reduce((sum, c) => sum + c.amount, 0) : 0;

    res.json({
      studentName: student.name,
      totalPayable,
      totalPaid,
      balance: totalPayable - totalPaid,
      payments
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getFeeStats = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const activeSession = await mongoose.model('AcademicSession').findOne({ isActive: true });
    if (!activeSession) {
      return res.status(404).json({ message: 'No active academic session found' });
    }

    // 1. Calculate Today's Collection
    const todayPayments = await FeePayment.find({
      paymentDate: { $gte: today }
    });
    const todayCollection = todayPayments.reduce((sum, p) => sum + p.amount, 0);

    // 2. Calculate Total Expected vs Total Collected for the Active Session
    // Using aggregation to handle large datasets efficiently

    // Total Collected
    const collectionStats = await FeePayment.aggregate([
      { $match: { academicSession: activeSession._id } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);
    const totalCollected = collectionStats.length > 0 ? collectionStats[0].total : 0;

    // Total Expected
    // We need to cross-reference Student Class with FeeStructure Components
    const students = await Student.find({ academicSession: activeSession._id, status: 'active' });
    const structures = await FeeStructure.find({ academicSession: activeSession._id });

    const structureMap = {};
    structures.forEach(s => {
      structureMap[s.class.toString()] = s.components.reduce((sum, c) => {
        if (c.frequency === 'monthly') {
          return sum + (c.amount * 12);
        }
        return sum + c.amount;
      }, 0);
    });

    let totalExpected = 0;
    students.forEach(student => {
      const classId = student.currentClass.toString();
      if (structureMap[classId]) {
        totalExpected += structureMap[classId];
      }
    });

    res.json({
      todayCollection,
      totalCollected,
      totalExpected,
      totalPending: totalExpected - totalCollected,
      activeSession: activeSession.sessionName
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all payments for a student
// @route   GET /api/fees/student/:id/payments
// @access  Private
const getStudentPayments = async (req, res) => {
  try {
    const payments = await FeePayment.find({ student: req.params.id })
      .sort({ paymentDate: -1 })
      .populate('receivedBy', 'name');
    res.json(payments);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  saveFeeStructure,
  getFeeStructures,
  recordPayment,
  getStudentFeeStatus,
  getStudentPayments,
  getFeeStats
};
