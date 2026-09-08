const mongoose = require('mongoose');

const studentSchema = mongoose.Schema(
  {
    admissionNumber: {
      type: String,
      required: true,
    },
    rollNumber: {
      type: String,
    },
    name: {
      type: String,
      required: true,
    },
    dob: {
      type: String,
      required: true,
    },
    gender: {
      type: String,
      required: true,
    },
    currentClass: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Class',
      required: true,
    },
    section: {
      type: String,
    },
    fatherName: {
      type: String,
      required: true,
    },
    motherName: {
      type: String,
      required: true,
    },
    guardianPhone: {
      type: String,
      required: true,
    },
    address: {
      type: String,
      required: true,
    },
    admissionDate: {
      type: String,
      required: true,
    },
    photoPath: {
      type: String,
    },
    status: {
      type: String,
      enum: ['active', 'inactive', 'graduated'],
      default: 'active',
    },
    academicSession: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'AcademicSession',
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// 1. Unique index to prevent duplicate roll numbers within a class/section/session
studentSchema.index(
  { academicSession: 1, currentClass: 1, section: 1, rollNumber: 1 },
  { unique: true, partialFilterExpression: { rollNumber: { $type: 'string' } } }
);

// 2. Scoped unique index for admissionNumber within the AcademicSession
studentSchema.index(
  { academicSession: 1, admissionNumber: 1 },
  { unique: true }
);

// Pre-save hook for validation
studentSchema.pre('save', async function () {
  if (this.isModified('currentClass') || this.isModified('section') || this.isModified('academicSession')) {
    const Class = mongoose.model('Class');
    const cls = await Class.findById(this.currentClass);

    if (!cls) {
      throw new Error('Referenced class does not exist');
    }

    // 3. Verify that currentClass actually belongs to the given academicSession
    if (String(cls.academicSession) !== String(this.academicSession)) {
      throw new Error('Class does not belong to the selected academic session');
    }

    // 2. Verify that section is valid for the class if the class has sections
    if (cls.sections && cls.sections.length > 0) {
      if (!this.section) {
        throw new Error(`Section is required for class '${cls.name}'`);
      }
      const validSection = cls.sections.some((s) => s.name === this.section);
      if (!validSection) {
        throw new Error(`Section '${this.section}' does not exist in class '${cls.name}'`);
      }
    } else {
      // If the class has no sections, the section field should be empty
      this.section = undefined;
    }
  }
});

module.exports = mongoose.model('Student', studentSchema);
