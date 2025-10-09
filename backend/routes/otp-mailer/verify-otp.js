import redisClient from '../../backend-utils/redisClient.js';

export default async function verifyOTPHandler(req, res) {
  const { email, otp } = req.body;
  if (!email || !otp) return res.status(400).json({ error: 'Email and OTP required.' });

  const storedOtp = await redisClient.get(`otp:${email}`);
  if (!storedOtp) return res.status(400).json({ error: 'OTP expired or not found.' });
  if (storedOtp !== otp) return res.status(400).json({ error: 'Invalid OTP.' });

  await redisClient.del(`otp:${email}`); // Optional: Remove after verification

  res.json({ success: true, verified: true });
}