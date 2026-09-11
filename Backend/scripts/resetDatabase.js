require('dotenv').config();
const mongoose = require('mongoose');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const modelNames = [
  'Student', 'Teacher', 'School', 'Class', 'AcademicSession',
  'FeePayment', 'FeeStructure', 'Exam', 'Mark', 'Schedule',
  'Certificate', 'LeaveRecord', 'SalaryRecord'
];

async function resetDB() {
  try {
    console.log('--- JAYASHA MANAGEMENT SOFTWARE DATABASE RESET ---');
    await mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URI);
    console.log('Connected to MongoDB.');

    rl.question('Do you want to wipe EVERYTHING including Principal login? (y/N): ', async (answer) => {
      const wipeAll = answer.toLowerCase() === 'y';

      const targetModels = [...modelNames];
      if (wipeAll) {
        targetModels.push('User', 'Principal');
      }

      console.log(`\nWiping: ${targetModels.join(', ')}...`);

      for (const name of targetModels) {
        try {
          // Explicitly require the model to register the schema with Mongoose
          const Model = require(`../models/${name}`);
          await Model.deleteMany({});
          console.log(`✓ Cleared ${name}`);
        } catch (err) {
          console.log(`× Could not clear ${name}: ${err.message}`);
        }
      }

      console.log('\nDatabase has been reset successfully.');
      process.exit(0);
    });
  } catch (error) {
    console.error('Error connecting to database:', error);
    process.exit(1);
  }
}

resetDB();
