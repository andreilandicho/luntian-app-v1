// backend/server.js
import express from 'express';
import authRouter from './routes/auth.js';
import usersRouter from './routes/users.js';
import barangaysRouter from './routes/barangays.js';
import reportsRouter from './routes/reports.js';
import eventsRouter from './routes/events.js';
import getReportsAssignedToAnOfficialRouter from './routes/getReportsAssignedToAnOfficial.js';
import viewOfficialRequestsRouter from './routes/viewOfficialRequests.js';
import leaderboardsRouter from './routes/leaderboards.js';
import notificationsRouter from './routes/user_notifications.js';
import notif from './routes/notif.js';
import "../lib/utils/cron.js"; // Import cron jobs to run them

//for web use
import cors from 'cors';

//for maintenance officials
import maintenanceOfficialRouter from './routes/maintenance/user_official.js'


const app = express();
app.use(cors()); // Enable CORS for all routes
app.use(express.json());

app.use('/auth', authRouter);
app.use('/users', usersRouter);
app.use('/barangays', barangaysRouter);
app.use('/reports', reportsRouter);
app.use('/events', eventsRouter);
app.use('/getReportsAssignedToAnOfficial', getReportsAssignedToAnOfficialRouter);
app.use('/viewOfficialRequests', viewOfficialRequestsRouter);
app.use('/leaderboards', leaderboardsRouter);
app.use('/notifications', notificationsRouter);
app.use("/notif", notif);


//for maintenance officials
app.use('/official', maintenanceOfficialRouter);


app.listen(3000, () => console.log('Server running on port 3000'));