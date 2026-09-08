const mongoose = require('mongoose');

const teacherSchema = mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
    },
    gender: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      required: true,
    },
    phone: {
      type: String,
      required: true,
    },
    subjects: [
      {
        type: String,
      },
    ],
    dob: {
      type: String,
      required: true,
    },
    photoPath: {
      type: String,
    },
    aadhaarFrontPath: {
      type: String,
    },
    aadhaarBackPath: {
      type: String,
    },
    maritalStatus: {
      type: String,
      required: true,
    },
    address: {
      type: String,
      required: true,
    },
    dateOfJoining: {
      type: String,
      required: true,
    },
    department: {
      type: String,
      required: true,
    },
    qualification: {
      type: String,
      required: true,
    },
    experience: {
      type: String,
      required: true,
    },
    status: {
      type: String,
      enum: ['active', 'inactive'],
      default: 'active',
    },
    classesTeaching: [
      {
        type: String,
      },
    ],
    sections: [
      {
        type: String,
      },
    ],
    isClassTeacher: {
      type: Boolean,
      default: false,
    },
    classTeacherOfClass: {
      type: String,
    },
    classTeacherOfSection: {
      type: String,
    },
    baseSalary: {
      type: Number,
      required: true,
      default: 0,
    },
    bankDetails: {
      bankName: String,
      accountNumber: String,
      ifscCode: String,
      branchName: String,
    },
    leaves: {
      totalAnnualLeaves: {
        type: Number,
        default: 12,
      },
      consumedLeaves: {
        type: Number,
        default: 0,
      },
    },
    emergencyContact: {
      name: String,
      phone: String,
      relation: String,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Teacher', teacherSchema);
