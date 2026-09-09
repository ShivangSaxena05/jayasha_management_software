const mongoose = require('mongoose');

const schoolSchema = new mongoose.Schema({
  schoolName: {
    type: String,
    required: [true, 'School name is required'],
    trim: true
  },
  address: {
    type: String,
    required: [true, 'Address is required']
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required']
  },
  email: {
    type: String,
    required: [true, 'Email is required']
  },
  affiliationLine: {
    type: String,
    default: ''
  },
  logoUrl: {
    type: String,
    default: ''
  },
  principalSignatureLabel: {
    type: String,
    default: 'Principal Signature'
  }
}, {
  timestamps: true
});

const School = mongoose.model('School', schoolSchema);

module.exports = School;
