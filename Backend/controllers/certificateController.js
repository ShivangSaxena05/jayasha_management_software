const Certificate = require('../models/Certificate');
const Student = require('../models/Student');

// @desc    Generate a new certificate
// @route   POST /api/certificates
// @access  Private
const generateCertificate = async (req, res) => {
  try {
    const { studentId, type, details } = req.body;

    const student = await Student.findById(studentId);
    if (!student) {
      return res.status(404).json({ success: false, message: 'Student not found' });
    }

    // Generate a unique certificate number (e.g., CERT-2023-001)
    const count = await Certificate.countDocuments();
    const certificateNumber = `CERT-${new Date().getFullYear()}-${(count + 1).toString().padStart(3, '0')}`;

    const certificate = await Certificate.create({
      student: studentId,
      type,
      certificateNumber,
      details,
      issuedBy: req.user ? req.user._id : null,
    });

    const populatedCertificate = await Certificate.findById(certificate._id).populate('student', 'name admissionNumber');

    res.status(201).json({
      success: true,
      data: populatedCertificate,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

// @desc    Get recent certificates
// @route   GET /api/certificates/recent
// @access  Private
const getRecentCertificates = async (req, res) => {
  try {
    const certificates = await Certificate.find()
      .sort({ createdAt: -1 })
      .limit(10)
      .populate('student', 'name');

    res.status(200).json({
      success: true,
      data: certificates,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error', error: error.message });
  }
};

module.exports = {
  generateCertificate,
  getRecentCertificates,
};
