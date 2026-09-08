const mongoose = require('mongoose');

const sectionSchema = mongoose.Schema({
  name: {
    type: String,
    required: true, // e.g., 'A', 'B'
  },
  classTeacher: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Teacher',
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
      required: true, // e.g., 'Class 1', 'LKG'
    },
    sections: [sectionSchema],
  },
  {
    timestamps: true,
  }
);

// Ensure a class name is unique within an academic session
classSchema.index({ academicSession: 1, name: 1 }, { unique: true });

module.exports = mongoose.model('Class', classSchema);
