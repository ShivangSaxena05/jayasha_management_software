const mongoose = require('mongoose');

const schoolSettingsSchema = mongoose.Schema(
  {
    schoolName: {
      type: String,
      required: true,
    },
    address: {
      type: String,
      required: true,
    },
    phone: {
      type: String,
      default: "",
    },
    email: {
      type: String,
      default: "",
    },
    website: {
      type: String,
      default: "",
    },
    affiliationNumber: {
      type: String,
      default: "",
    },
    schoolCode: {
      type: String,
      default: "",
    },
    logoPath: {
      type: String,
    },
    bannerPath: {
      type: String,
    },
    principalSignaturePath: {
      type: String,
    },
    themeColor: {
      type: String,
      default: "#0D47A1",
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('SchoolSettings', schoolSettingsSchema);
