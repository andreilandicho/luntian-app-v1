import express from 'express';
import supabase from '../../supabaseClient.js';

const router = express.Router();

// Get all pending reports assigned to an official by their user ID
router.get('/assigned-reports/:userId', async (req, res) => {
  const { userId } = req.params;
  
  try {
    const { data: assignments, error } = await supabase
      .from('report_assignments')
      .select(`
        reports!inner(
          report_id,
          description,
          photo_urls,
          created_at,
          status,
          priority,
          category,
          hazardous,
          report_deadline,
          lat,
          lon,
          anonymous,
          users!reports_user_id_fkey(
            name,
            user_profile_url
          ),
          report_assignments(
            officials:users!report_assignments_official_id_fkey(
            name
        )
      )
        )
      `)
      .eq('official_id', userId)
      .eq('reports.status', 'in_progress'); //all reports assigned are in progress by default

    if (error) {
      throw error;
    }

    // Transform the data to match your desired format
    const formattedReports = assignments.map(assignment => {
      const report = assignment.reports;
      
      return {
        reportId: report.report_id,
        reporterName: report.users.name,
        profileImage: report.users.user_profile_url || 'assets/profilepicture.png',
        anonymous: report.anonymous ?? false,
        reportDate: report.created_at,
        priority: report.priority,
        postImages: report.photo_urls || [],
        description: report.description,
        location: null, // to-do: add descriptive location in submit report for this
        isHazardous: Boolean(report.hazardous),
        reportCategory: report.category,
        status: report.status,
        reportDeadline: report.report_deadline,
        lat: report.lat,
        lon: report.lon,
        assignedOfficials: report.report_assignments.map(assignment => assignment.officials.name)
      };
    });

    res.json(formattedReports);
  } catch (error) {
    console.error('Error fetching assigned pending reports:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;