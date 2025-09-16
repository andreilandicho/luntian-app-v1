import express from "express";
import * as notifController from "../controllers/notifController.js";

const router = express.Router();

router.post("/Submit", notifController.createNotifSubmission);
router.post("/Status", notifController.createNotifStatus);
router.post("/Assign", notifController.createNotifAssign);
router.post("/Due", notifController.createNotifDue);

export default router;
