const mongoose = require('mongoose');
const FeeStructure = require('../models/FeeStructure');
const FeePayment = require('../models/FeePayment');
const Student = require('../models/Student');
const { sendSMS } = require('../utils/smsService');

// Helper to get elapsed months in a session up to current date
const getElapsedMonths = (sessionStartDate) => {
  const start = new Date(sessionStartDate);
  const end = new Date();
  const months = [];
  const monthNames = ["January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  let current = new Date(start.getFullYear(), start.getMonth(), 1);
  const stop = new Date(end.getFullYear(), end.getMonth(), 1);

  // Limit to 12 months maximum for a session
  let count = 0;
  while (current <= stop && count < 12) {
    months.push(monthNames[current.getMonth()]);
    current.setMonth(current.getMonth() + 1);
    count++;
  }
  return months;
};

// @desc    Save Fee Structure for classes
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
  const { studentId, academicSessionId, amount, paymentMode, category, remarks, paidMonths } = req.body;

  try {
    const payment = await FeePayment.create({
      student: studentId,
      academicSession: academicSessionId,
      amount,
      paymentMode,
      category,
      remarks,
      paidMonths: paidMonths || [],
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

    const structure = await FeeStructure.findOne({
      class: student.currentClass._id,
      academicSession: student.academicSession._id
    });

    const payments = await FeePayment.find({
      student: student._id,
      academicSession: student.academicSession._id
    });

    const totalPaid = payments.reduce((sum, p) => sum + p.amount, 0);
    const elapsedMonths = getElapsedMonths(student.academicSession.startDate);

    const paidMonths = payments
      .filter(p => p.category === 'monthly')
      .reduce((acc, p) => acc.concat(p.paidMonths || []), []);

    let totalPayable = 0;
    let pendingMonths = [];

    if (structure) {
      structure.components.forEach(c => {
        if (c.frequency === 'monthly') {
          const dueMonths = c.applicableMonths.filter(m => elapsedMonths.includes(m));
          totalPayable += (c.amount * dueMonths.length);
          const unpaid = dueMonths.filter(m => !paidMonths.includes(m));
          pendingMonths.push(...unpaid);
        } else {
          // Simplistic check for other categories: if any payment exists for that category, assume paid
          // Real production logic might need more granularity
          const cat = c.name.toLowerCase().includes('admission') ? 'admission' :
                      (c.name.toLowerCase().includes('annual') ? 'annual' :
                      (c.name.toLowerCase().includes('exam') ? 'exam' : 'other'));

          const paidForCat = payments.filter(p => p.category === cat).reduce((sum, p) => sum + p.amount, 0);
          if (paidForCat < c.amount) {
            totalPayable += c.amount;
          }
        }
      });
    }

    res.json({
      studentName: student.name,
      totalPayable,
      totalPaid,
      balance: Math.max(0, totalPayable - totalPaid),
      pendingMonths,
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

    const todayPayments = await FeePayment.find({
      paymentDate: { $gte: today }
    });
    const todayCollection = todayPayments.reduce((sum, p) => sum + p.amount, 0);

    const students = await Student.find({ academicSession: activeSession._id, status: 'active' });
    const structures = await FeeStructure.find({ academicSession: activeSession._id });
    const elapsedMonths = getElapsedMonths(activeSession.startDate);

    const classStructureMap = {};
    structures.forEach(s => {
      classStructureMap[s.class.toString()] = s.components;
    });

    const allPaymentsInSession = await FeePayment.find({ academicSession: activeSession._id });
    const studentPaymentData = {};
    let totalCollected = 0;

    allPaymentsInSession.forEach(p => {
      const sId = p.student.toString();
      if (!studentPaymentData[sId]) {
        studentPaymentData[sId] = { totalPaid: 0, paidMonths: [], categoriesPaid: {} };
      }
      studentPaymentData[sId].totalPaid += p.amount;
      totalCollected += p.amount;

      if (p.category === 'monthly' && p.paidMonths) {
        studentPaymentData[sId].paidMonths.push(...p.paidMonths);
      }
      studentPaymentData[sId].categoriesPaid[p.category] = (studentPaymentData[sId].categoriesPaid[p.category] || 0) + p.amount;
    });

    let totalPending = 0;
    let pendingStudents = 0;

    students.forEach(student => {
      const classId = student.currentClass.toString();
      const components = classStructureMap[classId];
      if (components) {
        const sId = student._id.toString();
        const pData = studentPaymentData[sId] || { totalPaid: 0, paidMonths: [], categoriesPaid: {} };
        let studentIsPending = false;
        let studentPendingAmount = 0;

        components.forEach(c => {
          if (c.frequency === 'monthly') {
            const dueMonths = c.applicableMonths.filter(m => elapsedMonths.includes(m));
            const unpaidMonths = dueMonths.filter(m => !pData.paidMonths.includes(m));
            if (unpaidMonths.length > 0) {
              studentPendingAmount += unpaidMonths.length * c.amount;
              studentIsPending = true;
            }
          } else {
            const cat = c.name.toLowerCase().includes('admission') ? 'admission' :
                        (c.name.toLowerCase().includes('annual') ? 'annual' :
                        (c.name.toLowerCase().includes('exam') ? 'exam' : 'other'));
            const paid = pData.categoriesPaid[cat] || 0;
            if (paid < c.amount) {
              studentPendingAmount += (c.amount - paid);
              studentIsPending = true;
            }
          }
        });

        if (studentIsPending) {
          pendingStudents++;
          totalPending += studentPendingAmount;
        }
      }
    });

    res.json({
      todayCollection,
      totalCollected,
      totalPending,
      pendingStudents,
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

// @desc    Get all fee payments
// @route   GET /api/fees/payments
// @access  Private
const getAllPayments = async (req, res) => {
  try {
    const payments = await FeePayment.find({})
      .sort({ paymentDate: -1 })
      .populate('student', 'name admissionNumber')
      .populate('receivedBy', 'name');
    res.json(payments);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all students with pending fees
// @route   GET /api/fees/pending
// @access  Private
const getPendingFees = async (req, res) => {
  try {
    const activeSession = await mongoose.model('AcademicSession').findOne({ isActive: true });
    if (!activeSession) {
      return res.status(404).json({ message: 'No active academic session found' });
    }

    const students = await Student.find({ academicSession: activeSession._id, status: 'active' })
      .populate('currentClass', 'name');
    const structures = await FeeStructure.find({ academicSession: activeSession._id });
    const elapsedMonths = getElapsedMonths(activeSession.startDate);

    const allPaymentsInSession = await FeePayment.find({ academicSession: activeSession._id });
    const paymentMap = {};
    allPaymentsInSession.forEach(p => {
      const sId = p.student.toString();
      if (!paymentMap[sId]) paymentMap[sId] = {};
      const cat = p.category;
      if (!paymentMap[sId][cat]) paymentMap[sId][cat] = { amount: 0, paidMonths: [] };
      paymentMap[sId][cat].amount += p.amount;
      if (p.paidMonths) {
        paymentMap[sId][cat].paidMonths.push(...p.paidMonths);
      }
    });

    const pendingList = [];
    students.forEach(student => {
      const classId = student.currentClass ? student.currentClass._id.toString() : null;
      if (classId) {
        const structure = structures.find(s => s.class.toString() === classId);
        if (structure) {
          const studentId = student._id.toString();
          const studentPayments = paymentMap[studentId] || {};
          const pendingCategories = [];
          let totalStudentPending = 0;
          let totalStudentPaid = 0;
          let totalStudentExpected = 0;

          structure.components.forEach(comp => {
            let cat = comp.name.toLowerCase();
            if (cat.includes('monthly')) cat = 'monthly';
            else if (cat.includes('admission')) cat = 'admission';
            else if (cat.includes('exam')) cat = 'exam';
            else if (cat.includes('annual')) cat = 'annual';
            else cat = 'other';

            const catPayment = studentPayments[cat] || { amount: 0, paidMonths: [] };
            const paid = catPayment.amount;

            let expected = 0;
            let pendingMonths = [];

            if (comp.frequency === 'monthly') {
              const dueMonths = comp.applicableMonths.filter(m => elapsedMonths.includes(m));
              expected = comp.amount * dueMonths.length;
              pendingMonths = dueMonths.filter(m => !catPayment.paidMonths.includes(m));

              if (paid >= expected) {
                pendingMonths = [];
              }
            } else {
              expected = comp.amount;
            }

            totalStudentPaid += paid;
            totalStudentExpected += expected;

            if (paid < expected || pendingMonths.length > 0) {
              const pending = Math.max(0, expected - paid);
              totalStudentPending += pending;
              pendingCategories.push({
                category: cat,
                originalName: comp.name,
                pendingAmount: pending,
                paidAmount: paid,
                totalExpected: expected,
                pendingMonths: pendingMonths
              });
            }
          });

          if (totalStudentPending > 0 || pendingCategories.length > 0) {
            pendingList.push({
              studentId: student._id,
              name: student.name,
              admissionNumber: student.admissionNumber,
              className: student.currentClass.name,
              section: student.section,
              fatherName: student.fatherName,
              pendingAmount: totalStudentPending,
              paidAmount: totalStudentPaid,
              totalExpected: totalStudentExpected,
              pendingCategories,
              student: student
            });
          }
        }
      }
    });

    pendingList.sort((a, b) => b.pendingAmount - a.pendingAmount);
    res.json(pendingList);
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
  getFeeStats,
  getAllPayments,
  getPendingFees
};
