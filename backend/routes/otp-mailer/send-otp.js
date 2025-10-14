import redisClient from '../../backend-utils/redisClient.js';
// import { transporter } from '../../backend-utils/mailer.js'; // Your Nodemailer setup
import { sendEmail } from '../../backend-utils/mailer.js';
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

export default async function sendOTPHandler(req, res) {
  const { email, subject } = req.body;
  if (!email) return res.status(400).json({ error: 'Email required.' });

  const otp = generateOTP();

  // Store OTP in Redis with a 5-minute expiry
  await redisClient.set(`otp:${email}`, otp, { EX: 300 });

  // Use provided subject or default to sign up verification
  const mailSubject = subject || 'Verify Luntian account creation';

  try {
    // Send email
    await sendEmail({
      // from: process.env.EMAIL_USER,
      // from: 'Luntian <no-reply@luntian.me>',
      to: email,
      subject: mailSubject,
      text: `Your verification code is: ${otp}`,
      html: `<p>Your verification code is: <b>${otp}</b></p>`,
    });

    res.json({ success: true });
  } catch (err) {
    console.error('Error sending OTP email:', err);
    res.status(500).json({ success: false, error: err.message });
  }
}