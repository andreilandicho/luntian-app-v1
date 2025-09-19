import express from "express";
import * as notifController from "../controllers/notifController.js";
import emailer from "../utils/emailer.js";
const router = express.Router();

router.post("/notifBarangay", notifController.reportNotifBarangay); //done
router.post("/officialAssignment", notifController.officialAssignment);
router.post("/reportStatusChange", notifController.reportStatusChange); //done
router.post("/dueDateReminder", notifController.dueDateReminder);
export default router;
