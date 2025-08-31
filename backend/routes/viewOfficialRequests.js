// get all accounts requesting to be a maintenance official for a specific barangay account
import express from 'express';
import supabase from '../supabaseClient.js';

const router = express.Router();

router.get('/:barangayId', async (req, res) => {
  const { barangayId } = req.params;

  try {
    // Join officials with users for more info
    const { data, error } = await supabase
      .from('officials')
      .select(`
        *,
        users:user_id (
          user_id,
          name,
          email,
          created_at
        )
      `)
      .eq('barangay_id', barangayId)
      .eq('is_approved', false);

    if (error) throw error;

    res.status(200).json(data);
  } catch (error) {
    console.error('Error fetching official requests:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

//patch method to approve or reject an official request
router.get('/:barangayId', async (req, res) => {
  const { barangayId } = req.params;

  try {
    // Join officials with users for more info
    const { data, error } = await supabase
      .from('officials')
      .select(`
        *,
        users:user_id (
          user_id,
          name,
          email,
          created_at
        )
      `)
      .eq('barangay_id', barangayId)
      .eq('is_approved', false);

    if (error) throw error;

    res.status(200).json(data);
  } catch (error) {
    console.error('Error fetching official requests:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
