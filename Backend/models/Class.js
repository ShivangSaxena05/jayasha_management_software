const mongoose = require('mongoose');

const sectionSchema = mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  classTeacher: {
    type: String, // Changed to String to match frontend for now, or use ref if preferred
  },
});

const timetableEntrySchema = mongoose.Schema({
  subject: { type: String, required: true },
  teacherName: { type: String, required: true }
}, { _id: false });

const feeComponentSchema = mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  amount: {
    type: Number,
    required: true,
    default: 0,
  },
  frequency: {
    type: String,
    enum: ['monthly', 'annually', 'one-time', 'term-wise'],
    default: 'monthly',
  },
  applicableMonths: {
    type: [String],
    default: ['April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', 'January', 'February', 'March'],
  },
});

const classSchema = mongoose.Schema(
  {
    academicSession: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      ref: 'AcademicSession',
    },
    name: {
      type: String,
      required: true,
    },
    classTeacher: {
      type: String,
      default: 'Not Assigned'
    },
    assistantTeacher: {
      type: String
    },
    sections: [sectionSchema],
    subjects: [
      {
        type: String,
      },
    ],
    feeStructure: [feeComponentSchema],
    numberOfPeriods: {
      type: Number,
      default: 6
    },
    timetable: {
      type: [[timetableEntrySchema]],
      default: function() {
        return Array(this.numberOfPeriods || 6).fill().map(() => Array(6).fill(null));
      }
    }
  },
  {
    timestamps: true,
  }
);

// Ensure a class name is unique within an academic session
classSchema.index({ academicSession: 1, name: 1 }, { unique: true });

module.exports = mongoose.model('Class', classSchema);
