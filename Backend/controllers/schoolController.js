const School = require('../models/School');

// @desc    Get school details
// @route   GET /api/school
// @access  Private
exports.getSchoolDetails = async (req, res) => {
  try {
    let school = await School.findOne();

    if (!school) {
      // Return empty defaults instead of null as per spec
      school = {
        schoolName: '',
        address: '',
        phone: '',
        email: '',
        affiliationLine: '',
        logoUrl: '',
        principalSignatureLabel: 'Principal Signature'
      };
    }

    res.status(200).json({
      status: 'success',
      data: school
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc    Update school details
// @route   PUT /api/school
// @access  Private (Principal)
exports.updateSchoolDetails = async (req, res) => {
  try {
    let school = await School.findOne();

    if (school) {
      school = await School.findByIdAndUpdate(school._id, req.body, {
        new: true,
        runValidators: true
      });
    } else {
      school = await School.create(req.body);
    }

    res.status(200).json({
      status: 'success',
      data: school
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};
