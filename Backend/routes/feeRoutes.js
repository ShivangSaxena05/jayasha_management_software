const express = require('express');
const router = express.Router();
const {
  saveFeeStructure,
  getFeeStructures,
  recordPayment,
  getStudentFeeStatus,
  getStudentPayments,
  getFeeStats,
  getAllPayments,
  getPendingFees
} = require('../controllers/feeController');
const { protect } = require('../middlewares/authMiddleware');

router.route('/structure').post(protect, saveFeeStructure).get(protect, getFeeStructures);
router.route('/payments').post(protect, recordPayment).get(protect, getAllPayments);
router.route('/pending').get(protect, getPendingFees);
router.route('/stats').get(protect, getFeeStats);
router.route('/student/:id').get(protect, getStudentFeeStatus);
router.route('/student/:id/payments').get(protect, getStudentPayments);

module.exports = router;
