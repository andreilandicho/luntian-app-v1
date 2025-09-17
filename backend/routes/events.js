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

// GET: All events (optionally filter by type and barangay)

//eto ang get method for fetching events based on type and barangay_id
router.get('/', async (req, res) => {
  try {
    const { type, barangay_id } = req.query;
    let query = supabase.from('volunteer_events').select('*');

    if (type === 'barangay' && barangay_id) {
      query = query.eq('barangay_id', parseInt(barangay_id)).eq('isPublic', false);
    } else if (type === 'public') {
      query = query.eq('isPublic', true);
    }
    // Only show approved events by default
    query = query.eq('approval_status', 'approved');
    query = query.order('event_date', { ascending: true });

    const { data, error } = await query;
    if (error) {
      return res.status(500).json({ error: error.message });
    }

    // Format for frontend
    const formatted = (data || []).map(ev => ({
      ...ev,
      dateTime: formatEventDate(ev.event_date),
      statusLabel: ev.approval_status,
      statusColor: getStatusColor(ev.approval_status),
      volunteers: ev.volunteers_needed,
    }));

    res.json(formatted);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET: Events for a specific barangay (barangay-exclusive)

//get method naman for fetching events for a specific barangay
// router.get('/barangay/:barangayId', async (req, res) => {
//   try {
//     const { barangayId } = req.params;
//     const { citizenId } = req.query;

//     const { data, error } = await supabase.rpc('get_barangay_events', {
//       p_barangay_id: parseInt(barangayId),
//       p_citizen_id: citizenId ? parseInt(citizenId) : null
//     });

//     if (error) {
//       console.error('Supabase error:', error);
//       return res.status(500).json({ error: 'Failed to fetch barangay events' });
//     }

//     res.json(data || []);

//   } catch (error) {
//     console.error('Error fetching barangay events:', error);
//     res.status(500).json({ error: 'Internal server error' });
//   }
// });
router.get('/barangay/:barangayId', async (req, res) => {
  try {
    const { barangayId } = req.params;
    const { citizenId } = req.query;

    // Fetch events with creator's name
    const { data: events, error } = await supabase
      .from('volunteer_events')
      .select(`
        *,
        creator:users(name)
      `)
      .eq('barangay_id', parseInt(barangayId))
      .eq('approval_status', 'approved')
      .eq('isPublic', false)
      .order('event_date', { ascending: true });

    if (error) {
      console.error('Supabase error:', error);
      return res.status(500).json({ error: 'Failed to fetch barangay events' });
    }

    // For each event, fetch interested count and if current user is interested
    const formatted = await Promise.all((events || []).map(async ev => {
      // Count interested participants
      const { count: interestedCount } = await supabase
        .from('volunteer_events_interested')
        .select('citizen_id', { count: 'exact', head: true })
        .eq('event_id', ev.event_id);

      // Check if current user is interested
      let isInterested = false;
      if (citizenId) {
        const { data: interestData } = await supabase
          .from('volunteer_events_interested')
          .select('citizen_id')
          .eq('event_id', ev.event_id)
          .eq('citizen_id', parseInt(citizenId))
          .limit(1);

        isInterested = interestData && interestData.length > 0;
      }

      const eventObj =  {
        ...ev,
        creator_name: ev.creator?.name ?? null,
        interested_count: interestedCount ?? 0,
        is_interested: isInterested,
      };
      
      delete eventObj.creator;

      return eventObj;
    }));

    res.json(formatted);
  } catch (error) {
    console.error('Error fetching barangay events:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});
// GET: All public events
//get method para sa system-wide public events
router.get('/public', async (req, res) => {
  try {
    const { citizenId } = req.query;

    // Fetch events with creator's name
    const { data: events, error } = await supabase
      .from('volunteer_events')
      .select(`
        *,
        creator:users(name)
      `)
      .eq('approval_status', 'approved')
      .eq('isPublic', true)
      .order('event_date', { ascending: true });

    if (error) {
      console.error('Supabase error:', error);
      return res.status(500).json({ error: 'Failed to fetch barangay events' });
    }

    // For each event, fetch interested count and if current user is interested
    const formatted = await Promise.all((events || []).map(async ev => {
      // Count interested participants
      const { count: interestedCount } = await supabase
        .from('volunteer_events_interested')
        .select('citizen_id', { count: 'exact', head: true })
        .eq('event_id', ev.event_id);

      // Check if current user is interested
      let isInterested = false;
      if (citizenId) {
        const { data: interestData } = await supabase
          .from('volunteer_events_interested')
          .select('citizen_id')
          .eq('event_id', ev.event_id)
          .eq('citizen_id', parseInt(citizenId))
          .limit(1);

        isInterested = interestData && interestData.length > 0;
      }

      const eventObj =  {
        ...ev,
        creator_name: ev.creator?.name ?? null,
        interested_count: interestedCount ?? 0,
        is_interested: isInterested,
      };
      
      delete eventObj.creator;

      return eventObj;
    }));

    res.json(formatted);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

//======================Updating interested button ===========================

//This is for getting the citizen_id using the user_id
router.get('/users/:userId/citizen-id', async (req, res) => {
  const { userId } = req.params;

  try {
    const { data, error } = await supabase
      .from('citizens')
      .select('citizen_id')
      .eq('user_id', userId)
      .single();

    if (error) return res.status(500).json({ error: error.message });
    res.json({ citizen_id: data.citizen_id });
  } catch (err) {
    console.error('Error fetching citizen ID:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /events/:eventId/interest - Toggle interest in an event
router.post('/events/:eventId/interest', async (req, res) => {
  try {
    const { eventId } = req.params;
    const { citizen_id } = req.body;

    if (!citizen_id) {
      return res.status(400).json({ error: 'citizen_id is required' });
    }

    // Check if user is already interested
    const { data: existingInterest, error: selectError } = await supabase
      .from('volunteer_events_interested')
      .select('*')
      .eq('citizen_id', citizen_id)
      .eq('event_id', eventId);

    let isInterested = false;

    if (existingInterest && existingInterest.length > 0) {
      // Remove interest
      const { error: deleteError } = await supabase
        .from('volunteer_events_interested')
        .delete()
        .eq('citizen_id', citizen_id)
        .eq('event_id', eventId);
      isInterested = false;
    } else {
      // Add interest
      const { error: insertError } = await supabase
        .from('volunteer_events_interested')
        .insert([{ citizen_id, event_id: eventId }]);
      isInterested = true;
    }

    res.json({ 
      success: true, 
      is_interested: isInterested,
      message: isInterested ? 'Interest added successfully' : 'Interest removed successfully'
    });

  } catch (error) {
    console.error('Error toggling event interest:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /events/:eventId/interest/add - Add interest to an event
router.post('/:eventId/interest/add', async (req, res) => {
  try {
    const { eventId } = req.params;
    const { citizen_id } = req.body;

    if (!citizen_id) {
      return res.status(400).json({ error: 'citizen_id is required' });
    }

    // Check if already interested
    const { data: existingInterest } = await supabase
      .from('volunteer_events_interested')
      .select('*')
      .eq('citizen_id', citizen_id)
      .eq('event_id', eventId);

    if (existingInterest && existingInterest.length > 0) {
      return res.status(400).json({ error: 'Already interested in this event' });
    }

    // Add interest
    await supabase
      .from('volunteer_events_interested')
      .insert([{ citizen_id, event_id: eventId }]);

    res.status(201).json({ 
      success: true, 
      message: 'Interest added successfully' 
    });

  } catch (error) {
    console.error('Error adding event interest:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE /events/:eventId/interest/remove - Remove interest from an event
router.delete('/:eventId/interest/remove', async (req, res) => {
  try {
    const { eventId } = req.params;
    const { citizen_id } = req.body;

    if (!citizen_id) {
      return res.status(400).json({ error: 'citizen_id is required' });
    }

    // Remove interest
    const { error: deleteError } = await supabase
      .from('volunteer_events_interested')
      .delete()
      .eq('citizen_id', citizen_id)
      .eq('event_id', eventId);

    if (deleteError) {
      console.error('Error removing event interest:', deleteError);
      return res.status(500).json({ error: 'Internal server error' });
    }

    res.json({ 
      success: true, 
      message: 'Interest removed successfully' 
    });

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Interest not found' });
    }

    res.json({ 
      success: true, 
      message: 'Interest removed successfully' 
    });

  } catch (error) {
    console.error('Error removing event interest:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

//======================Updating interested button ===========================



// GET: Interested user per event postings
//get method for displaying the number of interested volunteers for each event
router.get('/interested/:eventId', async (req, res) => {
  try {
    const { eventId } = req.params;

    const { data, error } = await supabase
      .from('volunteer_events_interested')
      //use count method to count the number of interested volunteers for a specific event
      .select('citizen_id', { count: 'exact' })
      .eq('event_id', parseInt(eventId));

    if (error) {
      console.error('Error fetching user events:', error);
      return res.status(500).json({ error: error.message });
    }
    res.json({ count: data?.length || 0 });
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});



// ================================PROFILE SCREEN ROUTES=================================

// GET: Events created by a user
//get method for displaying events in the user's profile
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const { data, error } = await supabase
      .from('volunteer_events')
      .select('*')
      .eq('created_by', parseInt(userId))
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching user events:', error);
      return res.status(500).json({ error: error.message });
    }

    const formatted = (data || []).map(ev => ({
      ...ev,
      dateTime: formatEventDate(ev.event_date),
      statusLabel: ev.approval_status,
      statusColor: getStatusColor(ev.approval_status),
      volunteers: ev.volunteers_needed,
    }));

    res.json(formatted);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// POST: Create a new event
//post event to create a new event and push it sa database
router.post('/', async (req, res) => {
  try {
    const {
      created_by, //user_id ng nagcreate ng event
      barangay_id, //barangay_id ng nagcreate ng event. isama sa business rules na a user can only create barangay exclusive event to his/her own barangay unless it is a public event
      title, 
      description,
      event_date,
      location, //kung saan gaganapin ang event. string not geom or point
      isPublic, //true kung public event, false kung barangay-exclusive
      photo_urls //photos na uploaded ng event creator. array of strings (URLs)
    } = req.body;

    const { data, error } = await supabase
      .from('volunteer_events') //volunteer_events ang table name
      .insert([{
        created_by,
        barangay_id,
        title,
        description,
        event_date,
        location,
        isPublic,
        photo_urls,
        approval_status: 'pending', // default value
      }])
      .select()
      .single();

    if (error) {
      console.error('Error creating event:', error);
      return res.status(500).json({ error: error.message });
    }

    res.status(201).json(data);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PATCH: Approve/Reject event (admin/official)
//patch is katulad lang ng put method, pero pwede lang i-update yung specific field na gusto mo na nasasatisfy yung condition
router.patch('/:id/approve', async (req, res) => {
  try {
    const { approval_status } = req.body;
    const { data, error } = await supabase
      .from('volunteer_events')
      .update({ approval_status })
      .eq('event_id', req.params.id)
      .select()
      .single();
    if (error) return res.status(500).json({ error: error.message });
    res.json(data);
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;