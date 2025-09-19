import express from "express";
import * as notifController from "../controllers/notifController.js";
const router = express.Router();

router.post("/notifBarangay", notifController.reportNotifBarangay); //done
router.post("/officialAssignment", notifController.officialAssignment);
router.post("/reportStatusChange", notifController.reportStatusChange); //done
export default router;
