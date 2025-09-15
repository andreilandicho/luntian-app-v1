// backend/routes/reports.js
import express from 'express';
import supabase from '../supabaseClient.js';

const router = express.Router();

// SLA mapping table
const slaTable = [
  { category: "Baradong Kanal", hazardous: false, priority: "Low", hours: 72 },
  { category: "Baradong Kanal", hazardous: false, priority: "Medium", hours: 48 },
  { category: "Baradong Kanal", hazardous: true, priority: "High", hours: 24 },
  { category: "Tambak ng Basura", hazardous: false, priority: "Low", hours: 168 },
  { category: "Tambak ng Basura", hazardous: true, priority: "Medium", hours: 48 },
  { category: "Tambak ng Basura", hazardous: true, priority: "High", hours: 24 },
  { category: "Masangsang na Estero", hazardous: false, priority: "Low", hours: 72 },
  { category: "Masangsang na Estero", hazardous: false, priority: "Medium", hours: 48 },
  { category: "Masangsang na Estero", hazardous: true, priority: "High", hours: 24 },
  { category: "Oil/Chemical Spills", hazardous: true, priority: "High", hours: 4 },
  { category: "General Littering", hazardous: false, priority: "Low", hours: 168 },
  { category: "Nabasag na Bote / Debris", hazardous: true, priority: "Medium", hours: 48 },
  { category: "Patay na Hayop (Dead Animals)", hazardous: true, priority: "Medium", hours: 48 },
  { category: "Illegal Dumping", hazardous: true, priority: "High", hours: 48 },
];

// Utility: calculate SLA deadline
function calculateDeadline(category, hazardous, priority) {
  const rule = slaTable.find(
    r => r.category.toLowerCase() === category.toLowerCase() &&
         r.hazardous === hazardous &&
         r.priority.toLowerCase() === priority.toLowerCase()
  );
  if (!rule) return new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // default 7 days
  return new Date(Date.now() + rule.hours * 60 * 60 * 1000);
}

// ------------------------- ROUTES -------------------------

// Get all reports (admin)
router.get('/', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('reports')
      .select('*')
      .order('created_at', { ascending: false });
    if (error) throw error;
    res.status(200).json(data);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get reports for a specific barangay
router.get('/barangay/:barangayId', async (req, res) => {
  try {
    const { barangayId } = req.params;
    const { data, error } = await supabase
      .from('reports')
      .select('*')
      .eq('barangay_id', parseInt(barangayId))
      .order('created_at', { ascending: false });
    if (error) throw error;
    res.status(200).json(data);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get reports by a specific user with vote info
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { data: reports, error } = await supabase
      .from('reports')
      .select('*')
      .eq('user_id', parseInt(userId))
      .order('created_at', { ascending: false });
    if (error) throw error;

    const enhancedReports = await Promise.all(reports.map(async report => {
      const { count: upvotes } = await supabase
        .from('report_votes')
        .select('*', { count: 'exact', head: true })
        .eq('report_id', report.report_id)
        .eq('vote_type', 'upvote');

      const { count: downvotes } = await supabase
        .from('report_votes')
        .select('*', { count: 'exact', head: true })
        .eq('report_id', report.report_id)
        .eq('vote_type', 'downvote');

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

    res.status(200).json(enhancedReports);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get solved reports for a barangay
router.get('/solved/:barangayId', async (req, res) => {
  try {
    const { barangayId } = req.params;
    const { data: reports, error } = await supabase
      .from('reports')
      .select(`
        *,
        report_solutions(*),
        report_assignments(official_id),
        report_ratings(average_user_rate)
      `)
      .eq('barangay_id', parseInt(barangayId))
      .eq('status', 'resolved')
      .order('created_at', { ascending: false });
    if (error) throw error;

    if (!reports || reports.length === 0) return res.json([]);

    const formattedReports = reports.map(report => {
      const assignedOfficials = report.report_assignments?.map(a => a.official_id) || [];
      const overallAverageRating = report.report_ratings?.length
        ? report.report_ratings.reduce((sum, r) => sum + (r.average_user_rate || 0), 0) / report.report_ratings.length
        : null;
      const solution = report.report_solutions?.[0] || {};

      const { report_solutions, report_assignments, report_ratings, ...rest } = report;
      return {
        ...rest,
        cleanup_notes: solution.cleanup_notes,
        solution_updated: solution.updated_at,
        after_photo_urls: solution.after_photo_urls,
        assigned_officials: assignedOfficials,
        overall_average_rating: overallAverageRating
      };
    });

    res.json(formattedReports);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create a new report with SLA calculation
router.post('/', async (req, res) => {
  try {
    const { userId, barangayId, description, photoUrls, location, category, priority, hazardous = false, anonymous = false } = req.body;
    const isHazardous = hazardous === true || hazardous === "true";
    const reportDeadline = calculateDeadline(category, isHazardous, priority);

    const { data, error } = await supabase
      .from('reports')
      .insert({
        user_id: parseInt(userId),
        barangay_id: parseInt(barangayId),
        description,
        photo_urls: photoUrls,
        location,
        category,
        priority,
        hazardous: isHazardous,
        anonymous,
        status: 'pending',
        report_deadline: reportDeadline
      })
      .select();

    if (error) throw error;
    res.status(201).json(data[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Vote on a report
router.post('/:reportId/vote', async (req, res) => {
  try {
    const { reportId } = req.params;
    const { userId, voteType } = req.body;

    await supabase
      .from('report_votes')
      .delete()
      .eq('report_id', reportId)
      .eq('voted_by', userId);

    if (voteType !== 'remove') {
      const { error: insertError } = await supabase
        .from('report_votes')
        .insert({ report_id: parseInt(reportId), voted_by: parseInt(userId), vote_type: voteType });
      if (insertError) throw insertError;
    }

    res.status(200).json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
