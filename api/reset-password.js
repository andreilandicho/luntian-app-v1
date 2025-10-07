import { createClient } from '@supabase/supabase-js';
import bcrypt from 'bcrypt';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

export default async function resetPasswordHandler(req, res) {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required.' });
  }

  try {
    // 1. Hash the password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // 2. Update the user's password
    const { error } = await supabase
      .from('users')
      .update({ password: hashedPassword })
      .eq('email', email);

    if (error) {
      return res.status(500).json({ error: error.message });
    }
    return res.json({ success: true, message: "Password updated successfully." });
  } catch (err) {
    return res.status(500).json({ error: "Failed to update password." });
  }
}