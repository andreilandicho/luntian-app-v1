// backend/server.js
import express from 'express';
import authRouter from './routes/auth.js';
import usersRouter from './routes/users.js';
import barangaysRouter from './routes/barangays.js';
import reportsRouter from './routes/reports.js';

const app = express();
app.use(express.json());

app.use('/auth', authRouter);
app.use('/users', usersRouter);
app.use('/barangays', barangaysRouter);
app.use('/reports', reportsRouter); // Add this line

app.listen(3000, () => console.log('Server running on port 3000'));