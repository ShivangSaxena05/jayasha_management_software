const mongoose = require('mongoose');

const examSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  session: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AcademicSession',
    required: true
  },
  startDate: Date,
  endDate: Date,
  type: {
    type: String,
    enum: ['Monthly Test', 'Mid Term', 'Half Yearly', 'Annual', 'Periodic Test', 'Final'],
    default: 'Monthly Test'
  },
  status: {
    type: String,
    enum: ['Scheduled', 'Ongoing', 'Completed', 'Result Declared'],
    default: 'Scheduled'
  },
  classes: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Class'
  }],
  datesheet: [{
    classId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Class'
    },
    className: String,
    subject: String,
    date: Date,
    startTime: String,
    durationHours: Number,
    maxMarks: {
      type: Number,
      default: 100
    }
  }]
}, { timestamps: true });

module.exports = mongoose.model('Exam', examSchema);
