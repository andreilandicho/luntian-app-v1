import cron from "node-cron";
import supabase from "../supabaseClient.js";
import { transporter } from "./mailer.js";
import { DateTime } from "luxon";
// Runs every 5 minutes in Philippine Time
cron.schedule(
  "*/5 * * * *",
  async () => {
    console.log(
      "⏰ Running due-date reminder job every 5 minutes (PH time)..."
    );

    try {
      const now = new Date();
      // Convert to Philippine Time (UTC+8)
      const todayStr = DateTime.now()
        .setZone("Asia/Manila") // PH timezone
        .toFormat("yyyy-MM-dd"); // YYYY-MM-DD

      // Fetch all reports that are due today
      const { data: reports, error } = await supabase
        .from("reports")
        .select("report_id, description, barangay_id")
        .eq("report_deadline", todayStr); // only reports due today

      if (error) throw error;

      for (const report of reports) {
        // Get barangay email
        const { data: barangay, error: barangayError } = await supabase
          .from("barangays")
          .select("contact_email")
          .eq("barangay_id", report.barangay_id)
          .single();

        if (barangayError || !barangay) {
          console.error(
            `Error fetching barangay email for report ${report.report_id}:`,
            barangayError
          );
          continue;
        }

        // Send reminder email
        await transporter.sendMail({
          from: process.env.EMAIL_USER,
          to: barangay.contact_email,
          subject: `Reminder: Report Due Today (${report.title})`,
          html: `
            <h3>Reminder: Report Due Today</h3>
            <p><strong>Report ID:</strong> ${report.report_id}</p>
            <p><strong>Description:</strong> ${report.description}</p>
          `,
        });

        console.log(`✅ Reminder sent for report ${report.report_id}`);
      }
    } catch (err) {
      console.error("🔥 Cron job failed:", err.message);
    }
  },
  {
    timezone: "Asia/Manila", // Set timezone explicitly
  }
);
