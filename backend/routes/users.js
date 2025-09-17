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

//get user data for profile screen
// Get user data with full address for profile screen
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    // Query to get user info with complete address
    const { data, error } = await supabase
      .from('users')
      .select(`
        *,
        barangays (
          name,
          city,
          barangay_masterlist (
            ADM4_EN,
            ADM3_EN,
            ADM2_EN,
            ADM1_EN,
            ADM0_EN
          )
        )
      `)
      .eq('user_id', userId)
      .single();

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    if (!data) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Extract address components
    const barangayData = data.barangays;
    let fullAddress = 'Address not available';
    
    if (barangayData && barangayData.barangay_masterlist) {
      const masterlist = barangayData.barangay_masterlist;
      const addressParts = [
        masterlist.ADM4_EN, // Barangay
        masterlist.ADM3_EN, // City/Municipality
        masterlist.ADM2_EN, // Province
        masterlist.ADM1_EN, // Region
        masterlist.ADM0_EN  // Country
      ].filter(part => part); // Remove null/undefined parts

      fullAddress = addressParts.join(', ');
    }

    // Format the response
    const userWithAddress = {
      user_id: data.user_id,
      name: data.name,
      email: data.email,
      barangay_id: data.barangay_id,
      barangay_name: barangayData?.name || null,
      city: barangayData?.city || null,
      full_address: fullAddress,
      role: data.role,
    };

    res.json(userWithAddress);
  } catch (err) {
    console.error('Error fetching user data:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
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

//for updating profile picture
router.post('/users/:userId/upload-profile-url', async (req, res) => {
  const { userId } = req.params;
  const { profileUrl } = req.body;

  if (!profileUrl) return res.status(400).json({ error: "Missing profileUrl" });

  try {
    await db.query(
      "UPDATE users SET user_profile_url = $1 WHERE user_id = $2",
      [profileUrl, userId]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;