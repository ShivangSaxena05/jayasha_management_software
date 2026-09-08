const Student = require('../models/Student');
const Class = require('../models/Class');
const AcademicSession = require('../models/AcademicSession');
const { sendSMS } = require('../utils/smsService');

// @desc    Register a new student admission
// @route   POST /api/students/admission
// @access  Private (Principal/Admin)
const registerAdmission = async (req, res) => {
  try {
    const {
      admissionNumber,
      rollNumber,
      name,
      dob,
      gender,
      currentClass, // Matches frontend JSON key
      section,
      fatherName,
      motherName,
      guardianPhone,
      address,
      admissionDate,
      photoPath,
      academicSession, // Matches frontend JSON key
    } = req.body;

    // Check if student with admission number already exists
    const studentExists = await Student.findOne({ admissionNumber });
    if (studentExists) {
      return res.status(400).json({ message: 'Student with this admission number already exists' });
    }

    // Verify class exists
    const classExists = await Class.findById(currentClass);
    if (!classExists) {
      return res.status(400).json({ message: 'Invalid Class selection' });
    }

    // Create student
    let student = await Student.create({
      admissionNumber,
      rollNumber,
      name,
      dob,
      gender,
      currentClass,
      section,
      fatherName,
      motherName,
      guardianPhone,
      address,
      admissionDate,
      photoPath,
      academicSession,
      status: 'active',
    });

    if (student) {
      // Populate for consistency with frontend expectations
      student = await student.populate([
        { path: 'currentClass', select: 'name' },
        { path: 'academicSession', select: 'sessionName year' }
      ]);

      // Send Welcome SMS to Parent
      const welcomeMessage = `Welcome to Jayasha Children's Academy! Admission for ${student.name} (ID: ${student.admissionNumber}) has been confirmed for Class ${student.currentClass.name}. Thank you for choosing us!`;

      // We don't await this to avoid delaying the response to the user
      sendSMS(student.guardianPhone, welcomeMessage);

      res.status(201).json({
        success: true,
        data: student,
      });
    } else {
      res.status(400).json({ message: 'Invalid student data' });
    }
  } catch (error) {
    console.error('Error in registerAdmission:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Get all students (with optional filters)
// @route   GET /api/students
// @access  Private
const getStudents = async (req, res) => {
  try {
    const { classId, section, admissionNumber } = req.query;
    let query = {};
    if (classId) query.currentClass = classId;
    if (section) query.section = section;
    if (admissionNumber) query.admissionNumber = admissionNumber;

    const students = await Student.find(query)
      .populate('currentClass', 'name')
      .populate('academicSession', 'year');

    res.status(200).json({
      success: true,
      count: students.length,
      data: students,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Get single student details
// @route   GET /api/students/:id
// @access  Private
const getStudentById = async (req, res) => {
  try {
    const student = await Student.findById(req.params.id)
      .populate('currentClass')
      .populate('academicSession');

    if (!student) {
      return res.status(404).json({ message: 'Student not found' });
    }

    res.status(200).json({
      success: true,
      data: student,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Send SMS message to all students in a class
// @route   POST /api/students/send-message
// @access  Private (Principal)
const sendMessageToClass = async (req, res) => {
  try {
    const { classId, section, message } = req.body;

    if (!classId || !message) {
      return res.status(400).json({ message: 'Class ID and message are required' });
    }

    let query = { currentClass: classId, status: 'active' };
    if (section) query.section = section;

    const students = await Student.find(query);

    if (students.length === 0) {
      return res.status(404).json({ message: 'No active students found in this class' });
    }

    const results = [];
    for (const student of students) {
      const success = await sendSMS(student.guardianPhone, message);
      results.push({
        studentName: student.name,
        phone: student.guardianPhone,
        success,
      });
    }

    res.status(200).json({
      success: true,
      message: `Attempted to send SMS to ${students.length} students`,
      details: results,
    });
  } catch (error) {
    console.error('Error in sendMessageToClass:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Update student details
// @route   PUT /api/students/:id
// @access  Private (Principal/Admin)
const updateStudent = async (req, res) => {
  try {
    const student = await Student.findById(req.params.id);

    if (!student) {
      return res.status(404).json({ message: 'Student not found' });
    }

    // If currentClass is being updated, verify it exists
    if (req.body.currentClassId) {
      const classExists = await Class.findById(req.body.currentClassId);
      if (!classExists) {
        return res.status(400).json({ message: 'Invalid Class selection' });
      }
      req.body.currentClass = req.body.currentClassId;
    }

    let updatedStudent = await Student.findByIdAndUpdate(
      req.params.id,
      { $set: req.body },
      { new: true, runValidators: true }
    );

    if (updatedStudent) {
      updatedStudent = await updatedStudent.populate([
        { path: 'currentClass', select: 'name' },
        { path: 'academicSession', select: 'sessionName year' }
      ]);
    }

    res.status(200).json({
      success: true,
      data: updatedStudent,
    });
  } catch (error) {
    console.error('Error in updateStudent:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = {
  registerAdmission,
  getStudents,
  getStudentById,
  updateStudent,
  sendMessageToClass,
};
