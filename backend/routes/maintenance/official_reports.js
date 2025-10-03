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
          descriptive_location,
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

    // ... inside your try block, after fetching assignments ...

    // Get the LATEST solution status for each report
    const { data: latestSolutions, error: solutionsError } = await supabase
      .from('report_solutions')
      .select('report_id, approval_status, updated_at')
      .in('report_id', assignments.map(a => a.reports.report_id))
      .order('updated_at', { ascending: false });

    if (solutionsError) throw solutionsError;

    // Create a map of the latest solution status for each report
    const latestSolutionMap = {};
    latestSolutions.forEach(solution => {
      if (!latestSolutionMap[solution.report_id]) {
        latestSolutionMap[solution.report_id] = solution.approval_status;
      }
    });

    // Filter reports: Only show those with NO solution or whose LATEST solution is 'rejected'
    const filteredReports = assignments.filter(assignment => {
      const reportId = assignment.reports.report_id;
      const latestStatus = latestSolutionMap[reportId];
      // Keep report if it has no solution, or the latest solution was rejected
      return !latestStatus || latestStatus === 'rejected';
    });

    // ... continue with transforming and returning filteredReports ...

    // Transform the data to match your desired format
    const formattedReports = filteredReports.map(assignment => {
      const report = assignment.reports;
      
      return {
        reportId: report.report_id,
        reporterName: report.users.name,
        profileImage: report.users.user_profile_url || 'assets/profile picture.png',
        reportDate: report.created_at,
        priority: report.priority,
        postImages: report.photo_urls || [],
        description: report.description,
        descriptiveLocation: report.descriptive_location,
        isHazardous: Boolean(report.hazardous),
        reportCategory: report.category,
        status: report.status,
        reportDeadline: report.report_deadline,
        lat: report.lat,
        lon: report.lon,
        descriptiveLocation: report.descriptive_location,
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
          descriptive_location,
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
        profileImage: report.users.user_profile_url || 'assets/profile picture.png',
        reportDate: report.created_at,
        solutionDate: solution.updated_at,
        priority: report.priority,
        originalImages: report.photo_urls || [],
        solutionImages: solution.after_photo_urls || [],
        description: report.description,
        cleanupNotes: solution.cleanup_notes,
        descriptiveLocation: report.descriptive_location,
        isHazardous: Boolean(report.hazardous),
        reportCategory: report.category,
        reportStatus: report.status,
        approval_status: solution.approval_status,
        reportDeadline: report.report_deadline,
        lat: report.lat,
        lon: report.lon,
        assignedOfficials: report.report_assignments.map(assignment => assignment.officials.name)
      };
    });

    res.json(formattedSolutions);
  } catch (error) {
    console.error('Error fetching submitted solutions:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;