import express from 'express';
import supabase from '../supabaseClient.js';
import cors from 'cors';

const router = express.Router();
router.use(cors());

// GET /api/badges/:userId
router.get('/:userId', async (req, res) => {
  const userId = req.params.userId;

  try {
    // 1. The Gina Lopez Badge: 10 reports in current month
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59).toISOString();

    const { data: reportsByUser, error: reportsError } = await supabase
      .from('reports')
      .select('report_id')
      .eq('user_id', userId)
      .gte('created_at', startOfMonth)
      .lte('created_at', endOfMonth);
    
    if (reportsError) throw reportsError;
    const topReporterProgress = reportsByUser?.length || 0;

    // 2. The Anna Oposa Badge: Marine-related reports
    const { data: marineReports, error: marineReportsError } = await supabase
      .from('reports')
      .select('report_id')
      .eq('user_id', userId)
      .in('category', ['Baradong Kanal', 'Masangsang Na Estero', 'Oil/Chemical Spills']);
    
    if (marineReportsError) throw marineReportsError;
    const ecoWarriorProgress = marineReports?.length || 0;

    // 3. The Rodne Galicha Badge: Organized events
    const { data: successfulEvents, error: eventsError } = await supabase
      .from('volunteer_events')
      .select('event_id')
      .eq('created_by', userId);
    
    if (eventsError) throw eventsError;
    const eventInitiatorProgress = successfulEvents?.length || 0;

    // Compose badges array (matching frontend expectations)
    const badges = [
      {
        name: "The Gina Lopez Badge",
        earned: topReporterProgress >= 10,
        description: "Get 10 reports approved this month.",
        progress: Math.min(topReporterProgress, 10),
        goal: 10,
      },
      {
        name: "The Anna Oposa Badge",
        earned: ecoWarriorProgress >= 3,
        description: "Report 3 marine or water-related issues.",
        progress: Math.min(ecoWarriorProgress, 3),
        goal: 3,
      },
      {
        name: "The Rodne Galicha Badge",
        earned: eventInitiatorProgress >= 1,
        description: "Successfully organize your first event.",
        progress: Math.min(eventInitiatorProgress, 1),
        goal: 1,
      }
    ];

    // ✅ Return just the badges array (not wrapped in object)
    res.json(badges);
    
  } catch (err) {
    console.error('Badges API Error:', err);
    res.status(500).json({ error: err.message || "Error fetching badges" });
  }
});

export default router;