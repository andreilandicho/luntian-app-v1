import express from 'express';
import supabase from '../supabaseClient.js';

const router = express.Router();

router.get('/', async (req, res) => {
  const { data, error } = await supabase
    .from('barangays')
    .select('barangay_id, name, masterlist:masterlist_id (ADM4_EN, ADM3_EN, ADM2_EN, ADM1_EN)');
  if (error) return res.status(500).json({ error: error.message });
  
  // Flatten the masterlist object so Flutter can easily use it
  const flattened = data.map(b => ({
    barangay_id: b.barangay_id,
    barangay_name: b.masterlist.ADM4_EN,
    barangay_municipality: b.masterlist.ADM3_EN,
    barangay_province: b.masterlist.ADM2_EN,
    barangay_region: b.masterlist.ADM1_EN,
  }));

  res.json(flattened);
});

//get method to return the barangay details that matches the given latitude and longitude
router.get('/match/:latitude/:longitude', async (req, res) => {
  try {
    const { latitude, longitude } = req.params;
    const lat = parseFloat(latitude);
    const lon = parseFloat(longitude); 
    
    //then do the point-in-polygon check using the supabase function
    //return the barangay id, and the matching barangay details in the masterlist of barangays
    const { data, error } = await supabase.rpc('get_barangay_by_location', {
      lat,
      lon
    }); 

    if (error) return res.status(500).json({ error: error.message });
    res.json(data);
  } catch (error) {
    console.error('Error fetching barangay by location:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});


//==================for user_official_profile
router.get('/:barangayId', async (req, res) => {
  const { barangayId } = req.params;
  const { data, error } = await supabase
    .from('barangays')
    .select('barangay_id, name, masterlist:masterlist_id (ADM4_EN, ADM3_EN, ADM2_EN, ADM1_EN)')
    .eq('barangay_id', barangayId);
  if (error) return res.status(500).json({ error: error.message });
  
  // Flatten the masterlist object so Flutter can easily use it
  const flattened = data.map(b => ({
    barangay_id: b.barangay_id,
    barangay_name: b.masterlist.ADM4_EN,
    barangay_municipality: b.masterlist.ADM3_EN,
    barangay_province: b.masterlist.ADM2_EN,
    barangay_region: b.masterlist.ADM1_EN,
  }));

  res.json(flattened);
});

export default router;