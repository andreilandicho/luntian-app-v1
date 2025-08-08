import express from 'express';
import supabase from '../supabaseClient.js';
import bcrypt from 'bcryptjs';

const router = express.Router();

// Get all users
router.get('/', async (req, res) => {
  const { data, error } = await supabase.from('users').select('*');
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

// Sign up endpoint
router.post('/', async (req, res) => {
  const { email, password, firstName, lastName, barangay_id, role } = req.body;

  if (!email || !password || !firstName || !lastName || !barangay_id || !role) {
    return res.status(400).json({ error: 'Missing required fields.' });
  }

  const { data: existingUsers } = await supabase
    .from('users')
    .select('email')
    .eq('email', email);

  if (existingUsers && existingUsers.length > 0) {
    return res.status(409).json({ error: 'Email already exists.' });
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  const { data: userData, error: userError } = await supabase
    .from('users')
    .insert([{
      name: `${firstName} ${lastName}`,
      email,
      password: hashedPassword,
      role,
      barangay_id,
      is_approved: role === 'official' ? false : true,
      created_at: new Date().toISOString()
    }])
    .select();

  if (userError) return res.status(500).json({ error: userError.message });

  const user_id = userData[0].user_id;

  if (role === 'official') {
    await supabase.from('officials').insert([{
      user_id,
      barangay_id,
      is_approved: false
    }]);
  } else if (role === 'citizen') {
    await supabase.from('citizens').insert([{
      user_id,
      barangay_id
    }]);
  }

  res.status(201).json({
    message: role === 'official'
      ? 'Account created. Pending approval by barangay admin.'
      : 'Account created successfully.'
  });
});

export default router;