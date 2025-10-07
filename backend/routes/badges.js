// badges.js - Updated with proper queries for your schema
import express from 'express';
import supabase from '../supabaseClient.js';
import cors from 'cors';

const router = express.Router();
router.use(cors());

// create badges inspired with environmentalists
//Gina Lopez - Environmentalist and Philanthropist query reports table for a user has reported 5 issues per month
//Illac Diaz - Social Entrepreneur query volunteer_events table for a user has organized 3 events
//Anna Oposa - Marine Conservationist query reports table for a user has reported 5 marine-related issues query reports submitted with category either '

// GET /api/badges/:userId
router.get('/:userId', async (req, res) => {
  const userId = req.params.userId;

  try {
    // 1. The Gina Lopez Badge: Query if a user has submitted a total of 10 reports for the current month (use user id and report_date)
    const { data: reportsByUser, error: reportsError } = await supabase
      .from('reports')
      .select('report_id')
      .eq('user_id', userId)
    if (reportsError) throw reportsError;
    const topReporterProgress = reportsByUser?.length || 0;

    //2. The Anna Oposa Badge: Query if a user has submitted a report with any of the following categories: Baradong Kanal, Masangsang Na Estero, Oil/Chemical Spills

    //3. The Rodne Galicha Badge: If a user has organized at least 1 event that has been marked as 'completed' or 'approved'

    
    const { data: cleanupEvents, error: cleanupEventsError } = await supabase
      .from('volunteer_events')
      .select('event_id')
      .eq('created_by', userId)
      .eq('status', 'approved'); // Only approved events
    if (cleanupEventsError) throw cleanupEventsError;
    const ecoWarriorProgress = cleanupEvents?.length || 0;

    // 3. 
    const { data: successfulEvents, error: eventsError } = await supabase
      .from('volunteer_events')
      .select('event_id')
      .eq('created_by', userId)
      .in('status', ['completed', 'approved']); // Count successful events
    if (eventsError) throw eventsError;
    const eventInitiatorProgress = successfulEvents?.length || 0;


    // Compose badges with proper qualification
    const badges = [
      {
        name: "The Gina Lopez Badge",
        earned: topReporterProgress >= 10,
        description: "Get 10 reports approved.",
        progress: Math.min(topReporterProgress, 10),
        goal: 10,
        qualification: ""
      },
      {
        name: "Eco Warrior",
        earned: ecoWarriorProgress >= 3,
        description: "Successfully complete 3 cleanup events.",
        progress: Math.min(ecoWarriorProgress, 3),
        goal: 3,
        qualification: "Completed events only"
      },
      {
        name: "Event Initiator",
        earned: eventInitiatorProgress >= 1,
        description: "Successfully organize your first event.",
        progress: Math.min(eventInitiatorProgress, 1),
        goal: 1,
        qualification: "Completed or approved events"
      }
    ];

    res.json({ 
      badges,
      stats: {
        reportsByUser: topReporterProgress,
        cleanupEvents: ecoWarriorProgress,
        successfulEvents: eventInitiatorProgress
      }
    });
  } catch (err) {
    console.error('Badges API Error:', err);
    res.status(500).json({ error: err.message || "Error fetching badges" });
  }
});

export default router;