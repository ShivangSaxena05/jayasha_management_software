const mongoose = require('mongoose');

const academicSessionSchema = mongoose.Schema(
  {
    sessionName: {
      type: String,
      required: true,
      unique: true, // e.g., "2025-2026"
    },
    startDate: {
      type: String,
      required: true,
    },
    endDate: {
      type: String,
      required: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('AcademicSession', academicSessionSchema);
