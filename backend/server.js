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
import rating from './routes/rating.js'
import "./backend-utils/cron.js"; // Import cron jobs to run them
import "./backend-utils/email-expired-reports.js";
import badgesRouter from './routes/badges.js';
import report_deleter from './routes/delete-report.js';
// import emailExpiredReportsHandler from './routes/email-expired-reports.js';
//for sign up email verification
import sendOTPHandler from './routes/otp-mailer/send-otp.js';
import verifyOTPHandler from './routes/otp-mailer/verify-otp.js';
import checkEmailCitizenHandler from './routes/check-email-citizen.js';
import checkEmailExistsHandler from './routes/check-email-exists.js';
import resetPasswordHandler from './routes/reset-password.js';
import barangay_masterlist from './routes/fetch-barangay-masterlist.js';


//for web use
import cors from 'cors';

//for maintenance officials
import maintenanceOfficialRouter from './routes/maintenance/user_official.js'
import officialReportsRouter from './routes/maintenance/official_reports.js'


const app = express();
app.use(cors()); // Enable CORS for all routes
app.use(express.json());


// app.post('/api/email-expired-reports', emailExpiredReportsHandler);
console.log("Registered /api/email-expired-reports route");

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
app.use("/rating", rating);
app.use('/badges', badgesRouter);
app.use("/barangay_masterlist", barangay_masterlist);
app.use("/report_deleter", report_deleter);

//for maintenance officials
app.use('/official', maintenanceOfficialRouter);
app.use('/official-reports', officialReportsRouter);

app.post('/api/check-email-citizen', checkEmailCitizenHandler);
app.post('/api/send-otp', sendOTPHandler);
app.post('/api/verify-otp', verifyOTPHandler);
app.post('/api/check-email-exists', checkEmailExistsHandler);
app.post('/api/reset-password', resetPasswordHandler);

app.listen(3000, () => console.log('Server running on port 3000'));