import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);

export default async function checkEmailExistsHandler(req, res) {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ error: 'Email required.' });
  }

  // Query users table by email (any role)
  const { data, error } = await supabase
    .from('users')
    .select('email')
    .eq('email', email)
    .maybeSingle();

  if (error) return res.status(500).json({ error: error.message });

  return res.json({ exists: !!data });
}