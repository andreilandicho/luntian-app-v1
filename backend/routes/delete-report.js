
import express from 'express';
import supabase from '../supabaseClient.js';

const router = express.Router();
router.delete('/delete/:reportId', async (req, res) => {
  const { reportId } = req.params;
  const { userId } = req.query;

  try {
    // Check if report exists and belongs to user
    const { data: report, error: fetchError } = await supabase
      .from('reports')
      .select('user_id, photo_urls')
      .eq('report_id', reportId)
      .single();

    if (fetchError || !report) {
      return res.status(404).json({ error: 'Report not found' });
    }

    // Verify ownership
    if (report.user_id !== userId) {
      return res.status(403).json({ error: 'You can only delete your own reports' });
    }

    // Delete associated photos from storage (optional)
    if (report.photo_urls && report.photo_urls.length > 0) {
      for (const url of report.photo_urls) {
        try {
          const fileName = url.split('/').pop();
          await supabase.storage
            .from('report-images')
            .remove([fileName]);
        } catch (storageError) {
          console.error('Error deleting photo:', storageError);
        }
      }
    }

    // Delete the report (cascade will handle related records)
    const { error: deleteError } = await supabase
      .from('reports')
      .delete()
      .eq('report_id', reportId);

    if (deleteError) {
      console.error('Error deleting report:', deleteError);
      return res.status(500).json({ error: 'Failed to delete report' });
    }

    res.json({ message: 'Report deleted successfully' });
  } catch (error) {
    console.error('Error in delete report:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;