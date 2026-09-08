const mongoose = require('mongoose');

const scheduleSchema = mongoose.Schema({
  academicSession: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'AcademicSession',
  },
  class: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'Class',
  },
  teacher: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Teacher',
  },
  teacherName: String, // Redundant but helpful for quick display
  subject: {
    type: String,
    required: true,
  },
  period: {
    type: Number,
    required: true,
  },
  day: {
    type: Number, // 0-5
    required: true,
  }
}, { timestamps: true });

// Ensure unique slot per class
scheduleSchema.index({ class: 1, period: 1, day: 1 }, { unique: true });

module.exports = mongoose.model('Schedule', scheduleSchema);
