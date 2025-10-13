import express from 'express';
import supabase from '../supabaseClient.js';

const router = express.Router();

// ...existing routes...

// GET /barangays/masterlist - Fetch all barangay masterlist with account indicators
router.get('/masterlist', async (req, res) => {
  try {
    const { data: masterlist, error: masterlistError } = await supabase
      .from('barangay_masterlist')
      .select(`
        barangay_masterlist_id,
        ADM4_PCODE,
        ADM4_EN,
        ADM3_EN,
        ADM2_EN,
        ADM1_EN,
        ADM0_EN,
        barangays!barangays_masterlist_id_fkey (
          barangay_id,
          name,
          contact_email
        )
      `)
      .order('ADM4_EN', { ascending: true });

    if (masterlistError) {
      console.error('Error fetching masterlist:', masterlistError);
      return res.status(500).json({ error: masterlistError.message });
    }

    // Transform data to include account existence indicator
    const enrichedMasterlist = masterlist.map(entry => {
      const hasAccount = entry.barangays && entry.barangays.length > 0;
      
      return {
        barangay_masterlist_id: entry.barangay_masterlist_id,
        pcode: entry.ADM4_PCODE,
        barangay: entry.ADM4_EN,
        municipality: entry.ADM3_EN,
        province: entry.ADM2_EN,
        region: entry.ADM1_EN,
        country: entry.ADM0_EN,
        // Full address for display
        full_address: [
          entry.ADM4_EN,
          entry.ADM3_EN,
          entry.ADM2_EN,
          entry.ADM1_EN,
          entry.ADM0_EN
        ].filter(Boolean).join(', '),
        // Account status
        has_account: hasAccount,
        account_info: hasAccount ? {
          barangay_id: entry.barangays[0].barangay_id,
          name: entry.barangays[0].name,
          contact_email: entry.barangays[0].contact_email
        } : null
      };
    });

    res.json(enrichedMasterlist);
  } catch (error) {
    console.error('Error in masterlist endpoint:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /barangays/masterlist/search - Search masterlist with query
router.get('/masterlist/search', async (req, res) => {
  const { query } = req.query;

  if (!query) {
    return res.status(400).json({ error: 'Search query is required' });
  }

  try {
    const searchTerm = `%${query}%`;

    const { data: masterlist, error: masterlistError } = await supabase
      .from('barangay_masterlist')
      .select(`
        barangay_masterlist_id,
        ADM4_PCODE,
        ADM4_EN,
        ADM3_EN,
        ADM2_EN,
        ADM1_EN,
        ADM0_EN,
        barangays!barangays_masterlist_id_fkey (
          barangay_id,
          name,
          contact_email
        )
      `)
      .or(`ADM4_EN.ilike.${searchTerm},ADM3_EN.ilike.${searchTerm},ADM2_EN.ilike.${searchTerm},ADM1_EN.ilike.${searchTerm}`)
      .order('ADM4_EN', { ascending: true })
      .limit(50);

    if (masterlistError) {
      console.error('Error searching masterlist:', masterlistError);
      return res.status(500).json({ error: masterlistError.message });
    }

    const enrichedMasterlist = masterlist.map(entry => {
      const hasAccount = entry.barangays && entry.barangays.length > 0;
      
      return {
        barangay_masterlist_id: entry.barangay_masterlist_id,
        pcode: entry.ADM4_PCODE,
        barangay: entry.ADM4_EN,
        municipality: entry.ADM3_EN,
        province: entry.ADM2_EN,
        region: entry.ADM1_EN,
        country: entry.ADM0_EN,
        full_address: [
          entry.ADM4_EN,
          entry.ADM3_EN,
          entry.ADM2_EN,
          entry.ADM1_EN,
          entry.ADM0_EN
        ].filter(Boolean).join(', '),
        has_account: hasAccount,
        account_info: hasAccount ? {
          barangay_id: entry.barangays[0].barangay_id,
          name: entry.barangays[0].name,
          contact_email: entry.barangays[0].contact_email
        } : null
      };
    });

    res.json(enrichedMasterlist);
  } catch (error) {
    console.error('Error in masterlist search:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /barangays/masterlist/:id - Get single masterlist entry
router.get('/masterlist/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const { data: entry, error } = await supabase
      .from('barangay_masterlist')
      .select(`
        *,
        barangays!barangays_masterlist_id_fkey (
          barangay_id,
          name,
          contact_email
        )
      `)
      .eq('barangay_masterlist_id', id)
      .single();

    if (error) {
      return res.status(404).json({ error: 'Masterlist entry not found' });
    }

    const hasAccount = entry.barangays && entry.barangays.length > 0;

    const enrichedEntry = {
      barangay_masterlist_id: entry.barangay_masterlist_id,
      pcode: entry.ADM4_PCODE,
      barangay: entry.ADM4_EN,
      municipality: entry.ADM3_EN,
      province: entry.ADM2_EN,
      region: entry.ADM1_EN,
      country: entry.ADM0_EN,
      full_address: [
        entry.ADM4_EN,
        entry.ADM3_EN,
        entry.ADM2_EN,
        entry.ADM1_EN,
        entry.ADM0_EN
      ].filter(Boolean).join(', '),
      has_account: hasAccount,
      account_info: hasAccount ? {
        barangay_id: entry.barangays[0].barangay_id,
        name: entry.barangays[0].name,
        contact_email: entry.barangays[0].contact_email
      } : null,
      // Include all other fields for reference
      date: entry.Date,
      validOn: entry.validOn,
      validTo: entry.validTo,
      shape_length: entry.Shape_Leng,
      shape_area: entry.Shape_Area,
      area_sqkm: entry.Area_SqKm
    };

    res.json(enrichedEntry);
  } catch (error) {
    console.error('Error fetching masterlist entry:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;