import express from 'express';
import supabase from '../supabaseClient.js';

const router = express.Router();

// Helper functions
function formatEventDate(dateString) {
  if (!dateString) return '';
  
  const date = new Date(dateString);
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  
  const month = months[date.getMonth()];
  const day = date.getDate();
  const year = date.getFullYear();
  
  let hours = date.getHours();
  const minutes = date.getMinutes();
  const ampm = hours >= 12 ? 'PM' : 'AM';
  
  hours = hours % 12;
  hours = hours ? hours : 12; // Convert 0 to 12
  const minutesStr = minutes < 10 ? '0' + minutes : minutes;
  
  return `${month} ${day}, ${year} • ${hours}:${minutesStr} ${ampm}`;
}

function getStatusColor(status) {
  switch (status?.toLowerCase()) {
    case 'approved': 
      return '#4CAF50';  // green
    case 'pending': 
      return '#FFC107';  // amber
    case 'rejected': 
      return '#F44336';  // red
    case 'for revision': 
      return '#FF9800';  // orange
    case 'in progress': 
      return '#2196F3';  // blue
    default: 
      return '#9E9E9E';  // grey
  }
}

// Get all events
router.get('/', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('events')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (error) {
      return res.status(500).json({ error: error.message });
    }
    
    res.json(data);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get events for a specific barangay
router.get('/barangay/:barangayId', async (req, res) => {
  try {
    const { barangayId } = req.params;
    
    const { data, error } = await supabase
      .from('events')
      .select('*')
      .eq('barangay_id', barangayId)
      .order('date_time', { ascending: true });
    
    if (error) {
      return res.status(500).json({ error: error.message });
    }
    
    res.json(data);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get events by user ID
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Get events created by the user
    const { data: createdEvents, error: createdError } = await supabase
      .from('events')
      .select(`
        event_id,
        user_id,
        title,
        description,
        additional_info,
        date_time,
        volunteers_needed,
        images,
        status,
        admin_comment,
        created_at,
        barangay_id
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false });
    
    if (createdError) {
      console.error('Error fetching created events:', createdError);
      return res.status(500).json({ error: createdError.message });
    }
    
    // Get events the user is participating in
    const { data: participations, error: participationsError } = await supabase
      .from('event_participants')
      .select('event_id')
      .eq('user_id', userId);
    
    if (participationsError) {
      console.error('Error fetching participations:', participationsError);
      return res.status(500).json({ error: participationsError.message });
    }
    
    // If user is participating in any events, fetch those events
    let participatingEvents = [];
    if (participations && participations.length > 0) {
      const eventIds = participations.map(p => p.event_id);
      
      const { data: events, error: eventsError } = await supabase
        .from('events')
        .select(`
          event_id,
          user_id,
          title,
          description,
          additional_info,
          date_time,
          volunteers_needed,
          images,
          status,
          admin_comment,
          created_at,
          barangay_id
        `)
        .in('event_id', eventIds);
      
      if (eventsError) {
        console.error('Error fetching participating events:', eventsError);
        return res.status(500).json({ error: eventsError.message });
      }
      
      participatingEvents = events || [];
    }
    
    // Format event data for frontend
    const formatEvent = (event, isCreator) => {
      const statusColor = getStatusColor(event.status);
      return {
        ...event,
        dateTime: formatEventDate(event.date_time),
        volunteers: event.volunteers_needed,
        statusLabel: event.status,
        statusColor: statusColor,
        isCreator: isCreator
      };
    };
    
    const formattedCreatedEvents = createdEvents.map(event => formatEvent(event, true));
    const formattedParticipatingEvents = participatingEvents.map(event => formatEvent(event, false));
    
    // Combine both lists and send as response
    const allEvents = [...formattedCreatedEvents, ...formattedParticipatingEvents];
    res.json(allEvents);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create a new event
router.post('/', async (req, res) => {
  try {
    const {
      userId,
      barangayId,
      title,
      description,
      additionalInfo,
      dateTime,
      volunteersNeeded,
      images
    } = req.body;
    
    const { data, error } = await supabase
      .from('events')
      .insert({
        user_id: userId,
        barangay_id: barangayId,
        title,
        description,
        additional_info: additionalInfo,
        date_time: dateTime,
        volunteers_needed: volunteersNeeded,
        images,
        status: 'pending'
      })
      .select();
    
    if (error) {
      console.error('Error creating event:', error);
      return res.status(500).json({ error: error.message });
    }
    
    res.status(201).json(data[0]);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;