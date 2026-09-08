/**
 * SMS Service Utility
 * You can integrate Twilio, Vonage, or any local SMS gateway here.
 */

const sendSMS = async (to, message) => {
  try {
    // This is a placeholder for actual SMS gateway integration
    // Example with a generic API:
    // await axios.post('https://api.sms-provider.com/send', { to, message, apiKey: '...' });

    console.log(`Sending SMS to ${to}: ${message}`);

    // For now, we return true to simulate success
    return true;
  } catch (error) {
    console.error(`Failed to send SMS to ${to}:`, error);
    return false;
  }
};

module.exports = { sendSMS };
