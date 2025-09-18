import express from 'express';
import supabase from '../../supabaseClient.js';

const router = express.Router();

// Get the data of the signed in barangay maintenance official
router.get('/:userId', async (req, res) => {
  const { userId } = req.params;
  try {
    const { data, error } = await supabase
      .from('users')
      .select('user_id, name, email, barangay_id, user_profile_url, official_id:officials(official_id)')
      .eq('user_id', userId)
      .single();

    if (error) {
      throw error;
    }
    const userObj =  {
      ...data,
      official_id: data.official_id?.official_id ?? null,
    };

    res.json(userObj);
  } catch (error) {
    console.error('Error fetching user official data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;