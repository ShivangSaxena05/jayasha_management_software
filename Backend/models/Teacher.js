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
    },
    address: {
      type: String,
    },
    dateOfJoining: {
      type: String,
    },
    department: {
      type: String,
    },
    qualification: {
      type: String,
    },
    experience: {
      type: String,
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
    schedule: [
      {
        classId: { type: mongoose.Schema.Types.ObjectId, ref: 'Class' },
        className: String,
        subject: String,
        period: Number,
        day: Number,
      }
    ]
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Teacher', teacherSchema);
