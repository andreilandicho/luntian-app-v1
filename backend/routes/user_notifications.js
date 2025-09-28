// backend/routes/notifications.js
import express from 'express';
import supabase from '../supabaseClient.js';

const router = express.Router();

router.get('/:userId', async (req, res) => {
  const userId = parseInt(req.params.userId, 10); // ✅ convert to int

  const { data, error } = await supabase
    .from('email')
    .select('id, user_id, title, content, created_at')
    .eq('user_id', userId)   // now matches INT column
    .order('created_at', { ascending: false });

  if (error) {
    console.error("Error fetching notifications:", error);
    return res.status(500).json({ error: error.message });
  }

  console.log("Notifications query result:", data); // debug
  res.json(data);
});

export default router;
