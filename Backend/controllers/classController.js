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
  const { name, sections, classTeacher, assistantTeacher, subjects, feeStructure, timetable, numberOfPeriods } = req.body;
  try {
    const oldClass = await Class.findById(id);
    if (!oldClass) {
      return res.status(404).json({ message: 'Class not found' });
    }

    // Basic validation or mapping if necessary
    const updateData = {
      name,
      classTeacher,
      assistantTeacher,
      subjects,
      feeStructure,
      timetable,
      numberOfPeriods
    };

    if (sections) {
      updateData.sections = sections.map(sec => (typeof sec === 'string' ? { name: sec } : sec));
    }

    const updatedClass = await Class.findByIdAndUpdate(
      id,
      updateData,
      { new: true }
    );

    // Sync with Teachers' schedules
    if (timetable) {
      const Teacher = require('../models/Teacher');

      // 1. Remove all existing schedule entries for this class from all teachers
      await Teacher.updateMany(
        {},
        { $pull: { schedule: { classId: id } } }
      );

      // 2. Add new schedule entries to teachers
      for (let p = 0; p < timetable.length; p++) {
        for (let d = 0; d < timetable[p].length; d++) {
          const entry = timetable[p][d];
          if (entry && entry.teacherName && entry.teacherName !== 'N/A' && entry.subject !== 'LUNCH') {
            // Find teacher by name (since we are storing teacherName in timetable)
            // Ideally we should use teacherId, but the current model uses name.
            // Let's find the teacher and update their schedule.
            await Teacher.findOneAndUpdate(
              { name: entry.teacherName },
              {
                $push: {
                  schedule: {
                    classId: id,
                    className: updatedClass.name,
                    subject: entry.subject,
                    period: p,
                    day: d
                  }
                }
              }
            );
          }
        }
      }
    }

    res.json(updatedClass);
  } catch (error) {
    console.error('Error updating class:', error);
    res.status(400).json({ message: error.message });
  }
};

module.exports = { saveClasses, getClasses, addClass, updateClass };
