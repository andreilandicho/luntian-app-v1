// backend/server.js
import express from "express";
import authRouter from "./routes/auth.js";
import usersRouter from "./routes/users.js";
import barangaysRouter from "./routes/barangays.js";
import reportsRouter from "./routes/reports.js";
import eventsRouter from "./routes/events.js";
import notif from "./routes/notif.js";
import getReportsAssignedToAnOfficialRouter from "./routes/getReportsAssignedToAnOfficial.js";
import viewOfficialRequestsRouter from "./routes/viewOfficialRequests.js";
import "./utils/cron.js"; // Import cron jobs to run them
const app = express();
app.use(express.json());

app.use("/auth", authRouter); //login
app.use("/users", usersRouter);
app.use("/barangays", barangaysRouter);
app.use("/reports", reportsRouter);
app.use("/events", eventsRouter);
app.use(
  "/getReportsAssignedToAnOfficial",
  getReportsAssignedToAnOfficialRouter
);
app.use("/viewOfficialRequests", viewOfficialRequestsRouter);
app.use("/notif", notif);

app.listen(3000, () => console.log("Server running on port 3000"));
