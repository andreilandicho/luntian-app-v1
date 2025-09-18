import express from 'express';
import supabase from '../supabaseClient.js';
//for web use
import cors from 'cors';

const router = express.Router();
router.use(cors()); // Enable CORS for all routes

// Helper function to get date filters for "today", "week", "month"
function getDateFilter(period) {
  const now = new Date();
  if (period === 'today') {
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    return { gte: start.toISOString() };
  }
  if (period === 'week') {
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 6);
    return { gte: start.toISOString() };
  }
  if (period === 'month') {
    const start = new Date(now.getFullYear(), now.getMonth(), 1);
    return { gte: start.toISOString() };
  }
  return {}; // no filter
}

// GET /api/leaderboards?period=today|week|month
router.get('/', async (req, res) => {
  const { period = 'today' } = req.query;
  const dateFilter = getDateFilter(period);

  try {
    // 1. Get all barangays
    const { data: allBarangays, error: barangaysErrorAll } = await supabase
      .from('barangays')
      .select('barangay_id, name, city, masterlist_id');
    if (barangaysErrorAll) {
      return res.status(500).json({ error: 'Failed to fetch barangays', details: barangaysErrorAll.message });
    }

    // 2. Get reports for period
    let reportQuery = supabase
      .from('reports')
      .select('report_id, barangay_id, status, created_at');

    if (dateFilter.gte) {
      reportQuery = reportQuery.gte('created_at', dateFilter.gte);
    }

    const { data: reports, error: reportsError } = await reportQuery;
    if (reportsError) {
      return res.status(500).json({ error: 'Failed to fetch reports', details: reportsError.message });
    }

    // 3. Get ratings for reports in period
    const reportIds = reports.map(r => r.report_id);
    let ratingsQuery = supabase
      .from('report_ratings')
      .select('report_id, average_user_rate');

    if (reportIds.length > 0) {
      ratingsQuery = ratingsQuery.in('report_id', reportIds);
    }
    const { data: ratings, error: ratingsError } = await ratingsQuery;
    if (ratingsError) {
      return res.status(500).json({ error: 'Failed to fetch ratings', details: ratingsError.message });
    }

    // 4. Map report_id -> barangay_id for ratings aggregation
    const reportIdToBarangay = {};
    reports.forEach(r => {
      reportIdToBarangay[r.report_id] = r.barangay_id;
    });

    // 5. Aggregate ratings per barangay
    const barangayRatings = {};
    ratings.forEach(rt => {
      const barangay_id = reportIdToBarangay[rt.report_id];
      if (!barangayRatings[barangay_id]) barangayRatings[barangay_id] = [];
      barangayRatings[barangay_id].push(rt.average_user_rate);
    });

    // 6. Aggregate report status counts per barangay
    const barangayReportStats = {};
    reports.forEach(r => {
      if (!barangayReportStats[r.barangay_id]) {
        barangayReportStats[r.barangay_id] = {
          active: 0,    // pending + in_progress
          resolved: 0,
          received: 0
        };
      }
      barangayReportStats[r.barangay_id].received += 1;
      if (['pending', 'in_progress'].includes(r.status)) {
        barangayReportStats[r.barangay_id].active += 1;
      }
      if (r.status === 'resolved') {
        barangayReportStats[r.barangay_id].resolved += 1;
      }
    });

    // 7. Compute leaderboard data for barangays with reports
    const barangaysWithReports = [];
    const barangaysNoReports = [];
    allBarangays.forEach(barangay => {
      const stats = barangayReportStats[barangay.barangay_id];
      if (stats && stats.received > 0) {
        // Compute average user rate
        const ratingsArr = barangayRatings[barangay.barangay_id] || [];
        const average_user_rate = ratingsArr.length > 0
          ? ratingsArr.reduce((a, b) => a + b, 0) / ratingsArr.length
          : 0.0;

        // Change mechanism: Use percentage scale from 1 to 5 (0–100%)
        const average_user_rate_percentage = (average_user_rate / 5) * 100;

        // Compute resolution rate: resolved / received (0–1)
        let resolution_rate = 0.0;
        if (stats.received > 0) {
          resolution_rate = stats.resolved / stats.received;
        }

        // For percent consistency, also scale resolution_rate to percent (0–100)
        const resolution_rate_percentage = resolution_rate * 100;

        // Compute leaderboard score using percent scale for both metrics
        const leaderboard_score = (resolution_rate_percentage * 0.7) + (average_user_rate_percentage * 0.3);

        barangaysWithReports.push({
          barangay_id: barangay.barangay_id,
          barangay_name: barangay.name,
          city: barangay.city,
          masterlist_id: barangay.masterlist_id,
          received_reports: stats.received,
          active_reports: stats.active,
          resolved_reports: stats.resolved,
          average_user_rate: average_user_rate_percentage, // Now percent
          resolution_rate: resolution_rate_percentage,     // Now percent
          leaderboard_score                              // Now percent (0–100)
        });
      } else {
        // Peaceful barangay (no reports in period)
        barangaysNoReports.push({
          barangay_id: barangay.barangay_id,
          barangay_name: barangay.name,
          city: barangay.city,
          masterlist_id: barangay.masterlist_id,
          peaceful_badge: true
        });
      }
    });

    // Sort barangays with reports by leaderboard_score
    barangaysWithReports.sort((a, b) => b.leaderboard_score - a.leaderboard_score);

    // Sort barangays without reports alphabetically
    barangaysNoReports.sort((a, b) => a.barangay_name.localeCompare(b.barangay_name));

    // Return as { with_reports: [...], no_reports: [...] }
    res.json({
      with_reports: barangaysWithReports,
      no_reports: barangaysNoReports
    });

  } catch (err) {
    res.status(500).json({ error: 'Internal server error', details: err.message });
  }
});

export default router;