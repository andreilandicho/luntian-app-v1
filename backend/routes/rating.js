// rating.js for rating the solved report cards
import express from 'express';
import supabase from '../supabaseClient.js';

const router = express.Router();

// POST endpoint for submitting ratings
router.post('/submit-rating', async (req, res) => {
  try {
    const { report_id, satisfaction_stars, response_time_stars, comments, user_id } = req.body;

    // Validate required fields
    if (!report_id || !satisfaction_stars || !response_time_stars || !user_id) {
      return res.status(400).json({ 
        error: 'Missing required fields: report_id, satisfaction_stars, response_time_stars, user_id' 
      });
    }

    // Validate rating range
    if (satisfaction_stars < 1 || satisfaction_stars > 5 || 
        response_time_stars < 1 || response_time_stars > 5) {
      return res.status(400).json({ 
        error: 'Ratings must be between 1 and 5' 
      });
    }

    // Calculate average rating
    const average_user_rate = (satisfaction_stars + response_time_stars) / 2;

    // Insert into report_ratings table
    const { data, error } = await supabase
      .from('report_ratings')
      .insert({
        report_id: report_id,
        rated_by: user_id,
        satisfaction_stars: satisfaction_stars,
        response_time_stars: response_time_stars,
        comments: comments || null,
        average_user_rate: average_user_rate,
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      console.error('Error inserting rating:', error);
      throw error;
    }

    res.status(201).json({
      message: 'Rating submitted successfully',
      rating: data
    });

  } catch (error) {
    console.error('Error in submit-rating endpoint:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE endpoint for removing ratings
router.delete('/delete-rating/:rating_id', async (req, res) => {
  try {
    const { rating_id } = req.params;
    const { user_id } = req.body; // User ID to verify ownership

    if (!rating_id || !user_id) {
      return res.status(400).json({ 
        error: 'Missing rating_id or user_id' 
      });
    }

    // First, verify the rating belongs to the user
    const { data: existingRating, error: fetchError } = await supabase
      .from('report_ratings')
      .select('rated_by')
      .eq('rating_id', rating_id)
      .single();

    if (fetchError) {
      return res.status(404).json({ error: 'Rating not found' });
    }

    if (existingRating.rated_by !== user_id) {
      return res.status(403).json({ error: 'Not authorized to delete this rating' });
    }

    // Delete the rating
    const { error: deleteError } = await supabase
      .from('report_ratings')
      .delete()
      .eq('rating_id', rating_id);

    if (deleteError) {
      throw deleteError;
    }

    res.json({ message: 'Rating deleted successfully' });

  } catch (error) {
    console.error('Error in delete-rating endpoint:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET endpoint to check if user has already rated a report
router.get('/user-rating/:report_id/:user_id', async (req, res) => {
  try {
    const { report_id, user_id } = req.params;

    const { data, error } = await supabase
      .from('report_ratings')
      .select('*')
      .eq('report_id', report_id)
      .eq('rated_by', user_id)
      .single();

    if (error && error.code !== 'PGRST116') { // PGRST116 is "not found" error
      throw error;
    }

    res.json({ 
      hasRated: !!data,
      userRating: data 
    });

  } catch (error) {
    console.error('Error in user-rating endpoint:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;