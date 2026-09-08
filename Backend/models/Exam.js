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
    enum: ['Periodic Test', 'Half Yearly', 'Annual', 'Monthly Test'],
    default: 'Monthly Test'
  },
  status: {
    type: String,
    enum: ['Scheduled', 'Ongoing', 'Completed', 'Result Declared'],
    default: 'Scheduled'
  }
}, { timestamps: true });

module.exports = mongoose.model('Exam', examSchema);
