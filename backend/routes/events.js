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
router.get('/barangay/:barangayId', async (req, res) => {
  try {
    const { barangayId } = req.params;

    const { data, error } = await supabase
      .from('volunteer_events')
      .select('*')
      .eq('barangay_id', parseInt(barangayId))
      .eq('isPublic', false)
      .eq('approval_status', 'approved')
      .order('event_date', { ascending: true });

    if (error) {
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

// GET: All public events
router.get('/public', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('volunteer_events')
      .select('*')
      .eq('isPublic', true)
      .eq('approval_status', 'approved')
      .order('event_date', { ascending: true });

    if (error) {
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

// GET: Events created by a user
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
router.post('/', async (req, res) => {
  try {
    const {
      created_by,
      barangay_id,
      title,
      description,
      event_date,
      location,
      isPublic,
      photo_urls
    } = req.body;

    const { data, error } = await supabase
      .from('volunteer_events')
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