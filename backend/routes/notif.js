import express from "express";
import * as notifController from "../controllers/notifController.js";
import * as notifEventController from "../controllers/notifEventController.js";
import * as notifCitizensForEventController from "../controllers/notifCitizensForEvent.js";
const router = express.Router();




router.post("/notifBarangay", notifController.reportNotifBarangay); //done
router.post("/officialAssignment", notifController.officialAssignment);
router.post("/reportStatusChange", notifController.reportStatusChange); //done

// for event notifications
router.post("/eventNotif", notifEventController.eventNotifBarangay); // New event notification endpoint
router.post("/eventApproval", notifEventController.eventApprovalNotification); // New event approval endpoint

router.post("/citizensForEvent", notifCitizensForEventController.notifyBarangayCitizens); // Notify citizens about event

export default router;