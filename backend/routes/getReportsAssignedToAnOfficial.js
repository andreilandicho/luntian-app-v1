//This file should must include:
//1. GET method to show all the reports assigned by the barangay account to its maintenance officials.
//2. POST method to submit the proof of completion of the report by the maintenance official.
import express from 'express';
import supabase from '../supabaseClient.js';

const router = express.Router();
//1. get method for showing the reports assigned to the signed-in official
router.get('/:official_id', async (req, res) => {
  try {
    const { official_id } = req.params;

    // Get assignments and join with reports table!
    const { data, error } = await supabase
      .from('report_assignments')
      .select(`
        *,
        reports:report_id (
          *
        )
      `)
      .eq('official_id', parseInt(official_id))
      .order('assigned_at', { ascending: true });
      //basically ay joining reports table to get the report details using the foreign key report_id

    if (error) {
      return res.status(500).json({ error: error.message });
    }
    res.json(data);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// POST: Submit proof of completion by maintenance official
router.post('/submit-proof', async (req, res) => {
  try {
    const { report_id, official_id, photo_urls, notes } = req.body;

    // Insert into report_updates
    const { error: updateError } = await supabase
      .from('report_updates')
      .insert([{
        report_id,
        updated_by: official_id,
        new_status: 'resolved',
        after_photo_urls: photo_urls,
        cleanup_notes: notes,
        updated_at: new Date().toISOString()
      }]);

    if (updateError) {
      return res.status(500).json({ error: updateError.message });
    }

    // Optionally update main report status
    const { error: statusError } = await supabase
      .from('reports')
      .update({ status: 'resolved' })
      .eq('report_id', report_id);

    if (statusError) {
      return res.status(500).json({ error: statusError.message });
    }

    res.status(201).json({ message: 'Proof submitted and report marked as resolved.' });
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});
export default router;