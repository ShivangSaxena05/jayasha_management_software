const Attendance = require('../models/Attendance');
const Student = require('../models/Student');

exports.markAttendance = async (req, res) => {
  try {
    const { attendanceRecords, date, sessionId } = req.body;

    if (!attendanceRecords || !Array.isArray(attendanceRecords)) {
      return res.status(400).json({ success: false, message: 'Invalid attendance data' });
    }

    const attendanceDate = new Date(date);
    attendanceDate.setHours(0, 0, 0, 0);

    const operations = attendanceRecords.map(record => ({
      updateOne: {
        filter: {
          student: record.studentId,
          date: attendanceDate
        },
        update: {
          $set: {
            student: record.studentId,
            class: record.classId,
            status: record.status,
            session: sessionId,
            date: attendanceDate,
            remarks: record.remarks
          }
        },
        upsert: true
      }
    }));

    await Attendance.bulkWrite(operations);

    res.status(200).json({
      success: true,
      message: 'Attendance marked successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

exports.getAttendanceByClass = async (req, res) => {
  try {
    const { classId, date } = req.query;

    const queryDate = new Date(date);
    queryDate.setHours(0, 0, 0, 0);

    const attendance = await Attendance.find({
      class: classId,
      date: queryDate
    }).populate('student', 'name admissionNumber rollNumber');

    res.status(200).json({
      success: true,
      data: attendance
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

exports.getStudentAttendanceReport = async (req, res) => {
  try {
    const { studentId, startDate, endDate } = req.query;

    const attendance = await Attendance.find({
      student: studentId,
      date: {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      }
    }).sort({ date: 1 });

    const stats = {
      Present: 0,
      Absent: 0,
      Late: 0,
      'Half Day': 0,
      total: attendance.length
    };

    attendance.forEach(record => {
      stats[record.status]++;
    });

    res.status(200).json({
      success: true,
      data: {
        records: attendance,
        stats
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
