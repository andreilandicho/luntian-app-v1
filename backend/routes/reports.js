// backend/routes/reports.js
import express from 'express';
import supabase from '../supabaseClient.js';

const router = express.Router();

// Get reports for a specific barangay
router.get('/barangay/:barangayId', async (req, res) => {
  try {
    const { barangayId } = req.params;
    const { userId } = req.query;
    
    const { data, error } = await supabase.rpc('get_reports_by_barangay', {
      p_barangay_id: parseInt(barangayId),
      p_user_id: parseInt(userId || '0')
    });
    
    if (error) {
      console.error('Error fetching reports:', error);
      return res.status(500).json({ error: error.message });
    }
    
    return res.status(200).json(data);
  } catch (err) {
    console.error('Server error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Add or update vote on a report
router.post('/:reportId/vote', async (req, res) => {
  try {
    const { reportId } = req.params;
    const { userId, voteType } = req.body;
    
    // Remove any existing votes by this user on this report
    const { error: deleteError } = await supabase
      .from('report_votes')
      .delete()
      .eq('report_id', reportId)
      .eq('voted_by', userId);
    
    if (deleteError) {
      console.error('Error deleting votes:', deleteError);
      return res.status(500).json({ error: deleteError.message });
    }
    
    // If not removing the vote, insert a new vote
    if (voteType !== 'remove') {
      const { error: insertError } = await supabase
        .from('report_votes')
        .insert({
          report_id: parseInt(reportId),
          voted_by: parseInt(userId),
          vote_type: voteType // Assuming your enum accepts 'upvote' or 'downvote'
        });
      
      if (insertError) {
        console.error('Error inserting vote:', insertError);
        return res.status(500).json({ error: insertError.message });
      }
    }
    
    return res.status(200).json({ success: true });
  } catch (err) {
    console.error('Server error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Create a new report
router.post('/', async (req, res) => {
  try {
    const {
      userId,
      barangayId,
      description,
      photoUrls,
      location,
      anonymous = false
    } = req.body;
    
    const { data, error } = await supabase
      .from('reports')
      .insert({
        user_id: parseInt(userId),
        barangay_id: parseInt(barangayId),
        description,
        photo_urls: photoUrls,
        location,
        anonymous,
        status: 'pending' // Your default status
      })
      .select();
    
    if (error) {
      console.error('Error creating report:', error);
      return res.status(500).json({ error: error.message });
    }
    
    return res.status(201).json(data[0]);
  } catch (err) {
    console.error('Server error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Get reports by user ID
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const { data, error } = await supabase
      .from('reports')
      .select(`
        report_id,
        user_id,
        description,
        photo_urls,
        status,
        created_at,
        anonymous,
        barangay_id,
        category,
        priority,
        location
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false });
    
    if (error) {
      console.error('Error fetching user reports:', error);
      return res.status(500).json({ error: error.message });
    }
    
    // Add voting information
    const enhancedReports = await Promise.all(data.map(async (report) => {
      // Get upvotes count
      const { count: upvotes } = await supabase
        .from('report_votes')
        .select('*', { count: 'exact', head: true })
        .eq('report_id', report.report_id)
        .eq('vote_type', 'upvote');
      
      // Get downvotes count
      const { count: downvotes } = await supabase
        .from('report_votes')
        .select('*', { count: 'exact', head: true })
        .eq('report_id', report.report_id)
        .eq('vote_type', 'downvote');
      
      // Check if current user has voted on this report
      const { data: userVote } = await supabase
        .from('report_votes')
        .select('vote_type')
        .eq('report_id', report.report_id)
        .eq('voted_by', userId);
      
      const hasUserUpvoted = userVote?.some(v => v.vote_type === 'upvote') || false;
      const hasUserDownvoted = userVote?.some(v => v.vote_type === 'downvote') || false;
      
      return {
        ...report,
        upvotes: upvotes || 0,
        downvotes: downvotes || 0,
        has_user_upvoted: hasUserUpvoted,
        has_user_downvoted: hasUserDownvoted
      };
    }));
    
    res.json(enhancedReports);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;