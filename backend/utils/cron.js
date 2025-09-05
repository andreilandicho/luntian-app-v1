import cron from "node-cron";
import supabase from "../supabaseClient.js";
import { transporter } from "./mailer.js";

cron.schedule("0 9 * * *", async () => {
  console.log("⏰ Running daily notification job...");

  try {
    // Example: select all notifications created today
    const { data: notifications, error } = await supabase
      .from("notifications")
      .select("*")
      .gte("created_at", new Date().toISOString().split("T")[0]); // adjust filter as needed

    if (error) throw error;

    for (const notif of notifications) {
      await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: notif.email, // assumes you stored email in supabase
        subject: `Reminder: ${notif.title}`,
        text: `This is a scheduled reminder.\n\nReport ID: ${notif.report_id}\nTitle: ${notif.title}`,
      });

      console.log(`✅ Reminder sent for report ${notif.report_id}`);
    }
  } catch (err) {
    console.error("🔥 Cron job failed:", err.message);
  }
});
