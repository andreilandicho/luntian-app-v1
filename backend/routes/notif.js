import express from "express";
import * as notifController from "../controllers/notifController.js";

const router = express.Router();

router.post("/Submit", notifController.createNotifSubmission);

export default router;
