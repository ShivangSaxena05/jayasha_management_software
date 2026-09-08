const Exam = require('../models/Exam');
const Mark = require('../models/Mark');
const Student = require('../models/Student');

exports.createExam = async (req, res) => {
  try {
    const { name, session, startDate, endDate, type } = req.body;
    const exam = await Exam.create({ name, session, startDate, endDate, type });
    res.status(201).json({ success: true, data: exam });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getExams = async (req, res) => {
  try {
    const { session } = req.query;
    const query = session ? { session } : {};
    const exams = await Exam.find(query).sort({ startDate: -1 });
    res.status(200).json({ success: true, data: exams });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.submitMarks = async (req, res) => {
  try {
    const { examId, classId, marksData } = req.body;
    // marksData: [{ studentId: '...', subjectMarks: [...] }]

    const operations = marksData.map(data => {
      const totalObtained = data.subjectMarks.reduce((sum, s) => sum + s.totalMarks, 0);
      const totalMax = data.subjectMarks.reduce((sum, s) => sum + s.maxMarks, 0);
      const percentage = (totalObtained / totalMax) * 100;

      return {
        updateOne: {
          filter: { student: data.studentId, exam: examId },
          update: {
            $set: {
              student: data.studentId,
              exam: examId,
              class: classId,
              subjectMarks: data.subjectMarks,
              totalObtained,
              percentage,
              result: percentage >= 33 ? 'Pass' : 'Fail'
            }
          },
          upsert: true
        }
      };
    });

    await Mark.bulkWrite(operations);
    res.status(200).json({ success: true, message: 'Marks submitted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getMarksByExamAndClass = async (req, res) => {
  try {
    const { examId, classId } = req.query;
    const marks = await Mark.find({ exam: examId, class: classId }).populate('student', 'name admissionNumber rollNumber');
    res.status(200).json({ success: true, data: marks });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getStudentReportCard = async (req, res) => {
  try {
    const { studentId, examId } = req.query;
    const markRecord = await Mark.findOne({ student: studentId, exam: examId })
      .populate('student')
      .populate('exam')
      .populate('class');

    if (!markRecord) {
      return res.status(404).json({ success: false, message: 'Marks not found for this student and exam' });
    }

    res.status(200).json({ success: true, data: markRecord });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
