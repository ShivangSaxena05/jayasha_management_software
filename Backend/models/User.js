const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please add a name'],
    },
    securityPin: {
      type: String,
      required: [true, 'Please add a security PIN'],
      unique: true, // Ensuring PIN is unique as it's the main identifier for the single principal
    },
    role: {
      type: String,
      default: 'principal',
    },
  },
  {
    timestamps: true,
  }
);

// Method to match security PIN
userSchema.methods.matchPin = async function (enteredPin) {
  return await bcrypt.compare(enteredPin, this.securityPin);
};

// Middleware to hash PIN before saving
userSchema.pre('save', async function () {
  if (this.isModified('securityPin')) {
    const salt = await bcrypt.genSalt(10);
    this.securityPin = await bcrypt.hash(this.securityPin, salt);
  }
});

module.exports = mongoose.model('User', userSchema);
