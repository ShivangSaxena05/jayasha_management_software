const mongoose = require('mongoose');

const feeComponentSchema = mongoose.Schema({
  name: {
    type: String,
    required: true, // e.g., 'Monthly Tuition Fee', 'Annual Admission Fee'
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
});

const feeStructureSchema = mongoose.Schema(
  {
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
    components: [feeComponentSchema],
  },
  {
    timestamps: true,
  }
);

// Ensure fee structure is unique for a class in a session
feeStructureSchema.index({ academicSession: 1, class: 1 }, { unique: true });

module.exports = mongoose.model('FeeStructure', feeStructureSchema);
