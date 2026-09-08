const mongoose = require('mongoose');

const markSchema = new mongoose.Schema({
  student: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  exam: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Exam',
    required: true
  },
  class: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Class',
    required: true
  },
  subjectMarks: [{
    subject: {
      type: String,
      required: true
    },
    theoryMarks: {
      type: Number,
      default: 0
    },
    practicalMarks: {
      type: Number,
      default: 0
    },
    totalMarks: {
      type: Number,
      default: 0
    },
    maxMarks: {
      type: Number,
      default: 100
    },
    grade: String,
    remarks: String
  }],
  totalObtained: Number,
  percentage: Number,
  result: {
    type: String,
    enum: ['Pass', 'Fail', 'Promoted', 'Compartment'],
    default: 'Pass'
  },
  rank: Number
}, { timestamps: true });

// Ensure unique mark record per student per exam
markSchema.index({ student: 1, exam: 1 }, { unique: true });

module.exports = mongoose.model('Mark', markSchema);
