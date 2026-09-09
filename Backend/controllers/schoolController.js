const SchoolSettings = require('../models/SchoolSettings');

// @desc    Get school settings
// @route   GET /api/school/settings
// @access  Public (or Private depending on needs, usually public for headers)
const getSettings = async (req, res) => {
  try {
    let settings = await SchoolSettings.findOne();
    if (!settings) {
      // Create default settings if none exist
      settings = await SchoolSettings.create({
        schoolName: "School Name",
        address: "School Address"
      });
    }
    res.json(settings);
  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
};

// @desc    Update school settings
// @route   PUT /api/school/settings
// @access  Private (Only Principal)
const updateSettings = async (req, res) => {
  try {
    let settings = await SchoolSettings.findOne();
    if (!settings) {
      settings = new SchoolSettings(req.body);
    } else {
      Object.assign(settings, req.body);
    }
    const updatedSettings = await settings.save();
    res.json(updatedSettings);
  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
};

module.exports = {
  getSettings,
  updateSettings,
};
