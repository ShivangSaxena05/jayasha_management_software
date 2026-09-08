const Class = require('../models/Class');
const FeeStructure = require('../models/FeeStructure');

// Save or Update classes for a session
const saveClasses = async (req, res) => {
  const { academicSessionId, classes } = req.body;
  try {
    // This could be used for initial setup or bulk update
    const classDocs = classes.map(cls => ({
      academicSession: academicSessionId,
      name: cls.className || cls.name,
      sections: cls.sections ? cls.sections.map(sec => (typeof sec === 'string' ? { name: sec } : sec)) : []
    }));

    // For simplicity in a "stack" like management, we might just insert new ones
    // or use a more sophisticated upsert.
    // However, the user specifically wants to "add" and "edit".

    const createdClasses = await Class.insertMany(classDocs);
    res.status(201).json(createdClasses);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getClasses = async (req, res) => {
  const { sessionId } = req.query;
  try {
    const filter = sessionId ? { academicSession: sessionId } : {};
    // Sort by createdAt to maintain "stack" / chronological order if needed
    const classes = await Class.find(filter).sort({ createdAt: 1 });
    res.json(classes);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const addClass = async (req, res) => {
  const { academicSessionId, name, sections } = req.body;
  try {
    const newClass = new Class({
      academicSession: academicSessionId,
      name,
      sections: sections ? sections.map(sec => ({ name: sec })) : []
    });
    const savedClass = await newClass.save();
    res.status(201).json(savedClass);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const updateClass = async (req, res) => {
  const { id } = req.params;
  const { name, sections, classTeacher } = req.body;
  try {
    const updatedClass = await Class.findByIdAndUpdate(
      id,
      { name, sections, classTeacher },
      { new: true }
    );
    res.json(updatedClass);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

module.exports = { saveClasses, getClasses, addClass, updateClass };
