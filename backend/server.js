import express from 'express';
import cors from 'cors';
import authRouter from './routes/auth.js';
import usersRouter from './routes/users.js';
import barangaysRouter from './routes/barangays.js';
import reportsRouter from './routes/reports.js';
import reportAssignmentsRouter from './routes/getReportsAssignedToAnOfficial.js';
const app = express();
const PORT = process.env.PORT || 3000;

// CORS configuration
// Use environment variable FRONTEND_URL if available, otherwise allow all origins (dev)
const allowedOrigin = process.env.FRONTEND_URL || '*';
app.use(cors({
  origin: allowedOrigin,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  credentials: true
}));

// Parse JSON bodies
app.use(express.json());

// Routes
app.use('/auth', authRouter);
app.use('/users', usersRouter);
app.use('/barangays', barangaysRouter);
app.use('/reports', reportsRouter);
app.use('/report_assignments', reportAssignmentsRouter);
app.use('/getReportsAssignedToAnOfficial', reportAssignmentsRouter);

// Test endpoint
app.get('/', (req, res) => {
  res.send('🚀 Backend is running! Try /auth, /users, /barangays, or /reports');
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`CORS allowed for: ${allowedOrigin}`);
});
