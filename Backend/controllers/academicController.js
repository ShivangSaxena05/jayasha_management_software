const AcademicSession = require('../models/AcademicSession');
const Class = require('../models/Class');

const saveAcademicSession = async (req, res) => {
  const { sessionName, startDate, endDate, classes } = req.body;
  try {
    const session = await AcademicSession.findOneAndUpdate(
      { sessionName },
      { startDate, endDate, isActive: true },
      { upsert: true, new: true }
    );

    // If classes are provided in the payload, save them too
    if (classes && Array.isArray(classes)) {
      for (const cls of classes) {
        await Class.findOneAndUpdate(
          { academicSession: session._id, name: cls.className || cls.name },
          {
            sections: cls.sections ? cls.sections.map(sec => (typeof sec === 'string' ? { name: sec } : sec)) : []
          },
          { upsert: true }
        );
      }
    }

    res.status(201).json(session);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getAcademicSessions = async (req, res) => {
  try {
    const sessions = await AcademicSession.find({});
    res.json(sessions);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getActiveSession = async (req, res) => {
  try {
    const session = await AcademicSession.findOne({ isActive: true });
    if (!session) {
      return res.status(404).json({ message: 'No active session found' });
    }
    res.json(session);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { saveAcademicSession, getAcademicSessions, getActiveSession };
