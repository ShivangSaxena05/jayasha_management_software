const mongoose = require('mongoose');

const feePaymentSchema = mongoose.Schema(
  {
    student: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Student',
      required: true,
    },
    academicSession: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'AcademicSession',
      required: true,
    },
    amount: {
      type: Number,
      required: true,
    },
    paymentDate: {
      type: Date,
      default: Date.now,
    },
    paymentMode: {
      type: String,
      enum: ['cash', 'online', 'cheque', 'other'],
      default: 'cash',
    },
    category: {
      type: String,
      enum: ['monthly', 'admission', 'exam', 'annual', 'other'],
      default: 'monthly',
    },
    remarks: {
      type: String,
    },
    receivedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('FeePayment', feePaymentSchema);
