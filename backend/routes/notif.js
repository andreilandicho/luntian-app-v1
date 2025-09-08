import { express } from "express";
import supabase from "../supabaseClient.js";
import { notifController } from "../controllers/notifController";
const router = Router.express();

router.post("/notifController/Submit", notifController.submitController);
router.post("/notifController/Status", notifController.statusController);
router.post("/notifController/Assign", notifController.assignController);
router.post("/notifController/Due", notifController.dueController);

export default router;
