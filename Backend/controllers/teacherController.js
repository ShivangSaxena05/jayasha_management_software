const Teacher = require('../models/Teacher');
const SalaryRecord = require('../models/SalaryRecord');
const LeaveRecord = require('../models/LeaveRecord');

const parseDate = (dateStr) => {
  if (!dateStr) return null;
  const [day, month, year] = dateStr.split('/').map(Number);
  return new Date(year, month - 1, day);
};

const saveTeachers = async (req, res) => {
  const { teachers } = req.body;

  try {
    const validatedTeachers = teachers.map(teacher => {
      // Calculate experience if DOJ is provided
      if (teacher.dateOfJoining && teacher.dob) {
        const dob = parseDate(teacher.dob);
        const doj = parseDate(teacher.dateOfJoining);
        const today = new Date();

        let ageAtJoining = doj.getFullYear() - dob.getFullYear();
        const m = doj.getMonth() - dob.getMonth();
        if (m < 0 || (m === 0 && doj.getDate() < dob.getDate())) {
          ageAtJoining--;
        }

        if (ageAtJoining < 18) { // Changed from 20 to 18 as per common standards
           // Just a warning or throw error?
        }

        let years = today.getFullYear() - doj.getFullYear();
        let months = today.getMonth() - doj.getMonth();
        if (months < 0 || (months === 0 && today.getDate() < doj.getDate())) {
          years--;
          months += 12;
        }

        teacher.experience = years > 0 ? `${years} years, ${months} months` : `${months} months`;
      }
      return teacher;
    });

    const createdTeachers = await Teacher.insertMany(validatedTeachers);
    res.status(201).json(createdTeachers);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const addTeacher = async (req, res) => {
  try {
    const teacher = await Teacher.create(req.body);
    res.status(201).json(teacher);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const updateTeacher = async (req, res) => {
  try {
    const teacher = await Teacher.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!teacher) return res.status(404).json({ message: 'Teacher not found' });
    res.json(teacher);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const deleteTeacher = async (req, res) => {
  try {
    const teacher = await Teacher.findByIdAndDelete(req.params.id);
    if (!teacher) return res.status(404).json({ message: 'Teacher not found' });
    res.json({ message: 'Teacher removed' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getTeachers = async (req, res) => {
  try {
    const teachers = await Teacher.find({});
    res.json(teachers);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Add salary record for a teacher
// @route   POST /api/teachers/:id/salary
// @access  Private
const addSalaryRecord = async (req, res) => {
  try {
    const teacherId = req.params.id;
    const { month, year, baseSalary, netSalary, paymentMethod, remarks } = req.body;

    const salaryRecord = await SalaryRecord.create({
      teacher: teacherId,
      month,
      year,
      baseSalary,
      allowances: 0,
      deductions: 0,
      netSalary: netSalary || baseSalary,
      paymentMethod,
      remarks,
    });

    res.status(201).json(salaryRecord);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// @desc    Get salary records for a teacher
// @route   GET /api/teachers/:id/salary
// @access  Private
const getSalaryRecords = async (req, res) => {
  try {
    const records = await SalaryRecord.find({ teacher: req.params.id }).sort({ year: -1, month: -1 });
    res.json(records);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Apply for leave
// @route   POST /api/teachers/:id/leaves
// @access  Private
const applyLeave = async (req, res) => {
  try {
    const { leaveType, startDate, endDate, reason } = req.body;
    const teacherId = req.params.id;

    const start = new Date(startDate);
    const end = new Date(endDate);
    const diffTime = Math.abs(end - start);
    const totalDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;

    const leave = await LeaveRecord.create({
      teacher: teacherId,
      leaveType,
      startDate,
      endDate,
      totalDays,
      reason,
    });

    res.status(201).json(leave);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// @desc    Get leave records for a teacher
// @route   GET /api/teachers/:id/leaves
// @access  Private
const getLeaveRecords = async (req, res) => {
  try {
    const leaves = await LeaveRecord.find({ teacher: req.params.id }).sort({ startDate: -1 });
    res.json(leaves);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update leave status (Approve/Reject)
// @route   PUT /api/teachers/leaves/:leaveId
// @access  Private
const updateLeaveStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const leave = await LeaveRecord.findById(req.params.leaveId);

    if (!leave) return res.status(404).json({ message: 'Leave record not found' });

    leave.status = status;
    leave.approvedBy = req.user._id;
    await leave.save();

    // If approved, update consumed leaves in Teacher model
    if (status === 'Approved') {
      const teacher = await Teacher.findById(leave.teacher);
      if (teacher) {
        teacher.leaves.consumedLeaves += leave.totalDays;
        await teacher.save();
      }
    }

    res.json(leave);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

module.exports = {
  saveTeachers,
  addTeacher,
  updateTeacher,
  deleteTeacher,
  getTeachers,
  addSalaryRecord,
  getSalaryRecords,
  applyLeave,
  getLeaveRecords,
  updateLeaveStatus
};
