import express from 'express';
import supabase from '../supabaseClient.js';
import bcrypt from 'bcryptjs';

const router = express.Router();

router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  console.log("=== LOGIN START ===");
  console.log("Body:", req.body);

  try {
    const { data: user, error } = await supabase
      .from('users')
      .select('user_id,citizen:citizens(citizen_id),name,email,password,role,barangay_id,is_approved,is_active,can_post_anonymously,created_at')
      .eq('email', email)
      .single();
    
    console.log("Raw user from Supabase:", user);
    console.log("User keys:", Object.keys(user));

    console.log("Supabase user row:", user);
    if (error) {
      console.error("Select error:", error);
      return res.status(500).json({ error: "Database error", details: error });
    }
    if (!user) {
      return res.status(401).json({ error: "No account with this email." });
    }

    console.log("Row keys:", Object.keys(user));

    const passwordMatch = await bcrypt.compare(password, user.password);
    console.log("Password match:", passwordMatch);

    if (!passwordMatch) {
      return res.status(401).json({ error: "Wrong password." });
    }

    if (user.role === 'official' && user.is_approved !== true) {
      return res.status(403).json({ error: "Account verification still pending." });
    }

    const userResponse = {
      id: user.user_id ?? null,
      user_id: user.user_id ?? null,
      citizen_id: user.citizen ? user.citizen.citizen_id : null,
      name: user.name ?? null,
      email: user.email ?? null,
      role: user.role ?? null,
      barangay_id: user.barangay_id ?? null,
      verified: user.is_approved ?? null,
      is_approved: user.is_approved ?? null,
      is_active: user.is_active ?? null,
      can_post_anonymously: user.can_post_anonymously ?? null,
      created_at: user.created_at ?? null
    };
    

    const fullResponse = { message: "Login successful.", user: userResponse };
    console.log("Full response about to send:", fullResponse);

    res.status(200).json(fullResponse);
  } catch (err) {
    console.error("Unhandled login error:", err);
    res.status(500).json({ error: "Server error during login" });
  } finally {
    console.log("=== LOGIN END ===");
  }
});


// ===============================
// Change password endpoint
// POST /auth/change-password
// ===============================
router.post('/change-password', async (req, res) => {
  const { userId, oldPassword, newPassword } = req.body;

  if (!userId || !oldPassword || !newPassword) {
    return res.status(400).json({ error: 'Missing userId, oldPassword, or newPassword.' });
  }

  // 1. Get user row
  const { data: user, error } = await supabase
    .from('users')
    .select('password')
    .eq('user_id', userId)
    .single();

  if (error) return res.status(500).json({ error: error.message });
  if (!user) return res.status(404).json({ error: 'User not found.' });

  // 2. Compare old password
  const passwordMatch = await verifyPassword(oldPassword, user.password);
  if (!passwordMatch) {
    return res.status(401).json({ error: 'Old password is incorrect.' });
  }

  // 3. Validate new password (enforce some rules)
  if (
    typeof newPassword !== 'string' ||
    newPassword.length < 8 ||
    !/[A-Z]/i.test(newPassword) ||
    !/\d/.test(newPassword)
  ) {
    return res.status(400).json({ error: 'New password must be at least 8 characters, include letters and numbers.' });
  }

  // 4. Hash new password and update
  const newHashedPassword = await bcrypt.hash(newPassword, 10);

  const { error: updateError } = await supabase
    .from('users')
    .update({ password: newHashedPassword })
    .eq('user_id', userId);

  if (updateError) return res.status(500).json({ error: updateError.message });

  res.json({ message: 'Password changed successfully.' });
});

// Real password verification function
async function verifyPassword(plainText, hashedPassword) {
  if (typeof plainText !== 'string' || typeof hashedPassword !== 'string') return false;
  try {
    return await bcrypt.compare(plainText, hashedPassword);
  } catch (e) {
    console.error('Error verifying password:', e);
    return false;
  }
}

export default router;