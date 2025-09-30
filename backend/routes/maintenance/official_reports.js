import express from 'express';
import supabase from '../../supabaseClient.js';

const router = express.Router();

// Get all pending reports assigned to an official by their user ID
router.get('/assigned-reports/:userId', async (req, res) => {
  const { userId } = req.params;
  
  try {
    // First, get reports assigned to this official
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
      .eq('reports.status', 'in_progress');

    if (error) {
      throw error;
    }

    // Get report IDs that have PENDING or APPROVED solutions only
    const { data: solutionReportIds, error: solutionsError } = await supabase
      .from('report_solutions')
      .select('report_id, approval_status')
      .in('approval_status', ['pending', 'approved']);
      
    if (solutionsError) {
      throw solutionsError;
    }

    // Extract just the report IDs with pending or approved solutions
    const reportsWithPendingOrApprovedSolutions = solutionReportIds.map(item => item.report_id);

    // Filter out ONLY reports with pending or approved solutions
    // (keeps reports with no solutions or rejected solutions)
    const filteredReports = assignments.filter(assignment => 
      !reportsWithPendingOrApprovedSolutions.includes(assignment.reports.report_id)
    );

    // Transform the data to match your desired format
    const formattedReports = filteredReports.map(assignment => {
      const report = assignment.reports;
      
      return {
        reportId: report.report_id,
        reporterName: report.users.name,
        profileImage: report.users.user_profile_url || 'assets/profilepicture.png',
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

// # 2. New Endpoint: Submitted Solutions (ALL solutions with status)

// Get all solutions submitted by an official (pending/approved/rejected)
router.get('/submitted-solutions/:userId', async (req, res) => {
  const { userId } = req.params;
  
  try {
    // Get all solutions submitted by this official
        const { data: solutions, error } = await supabase
      .from('report_solutions')
      .select(`
        update_id,
        report_id,
        after_photo_urls,
        cleanup_notes,
        updated_at,
        approval_status,
        reports(
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
          users!reports_user_id_fkey(
            name,
            user_profile_url
          )
        )
      `)
      .eq('updated_by', userId)
      .order('updated_at', { ascending: false });

    if (error) {
      throw error;
    }

    // Transform the data
    const formattedSolutions = solutions.map(solution => {
      const report = solution.reports;
      
      return {
        solutionId: solution.update_id,
        reportId: solution.report_id,
        reporterName: report.users.name,
        profileImage: report.users.user_profile_url || 'assets/profilepicture.png',
        reportDate: report.created_at,
        solutionDate: solution.updated_at,
        priority: report.priority,
        originalImages: report.photo_urls || [],
        solutionImages: solution.after_photo_urls || [],
        description: report.description,
        cleanupNotes: solution.cleanup_notes,
        location: null, // to-do: add descriptive location
        isHazardous: Boolean(report.hazardous),
        reportCategory: report.category,
        reportStatus: report.status,
        solutionStatus: solution.approval_status,
        reportDeadline: report.report_deadline,
        lat: report.lat,
        lon: report.lon
      };
    });

    res.json(formattedSolutions);
  } catch (error) {
    console.error('Error fetching submitted solutions:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;