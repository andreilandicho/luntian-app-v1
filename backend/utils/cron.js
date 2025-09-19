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
      // code below is to convert to PH time and format to YYYY-MM-DD
      const todayStr = DateTime.now()
        .setZone("Asia/Manila")
        .toFormat("yyyy-MM-dd");

      /*   const tomorrowStr = DateTime.now()
        .setZone("Asia/Manila") 
        .plus({ days: 1 }) 
        .toFormat("yyyy-MM-dd"); 
 */ //use to send reminders a day before the deadline for final code current code is for test

      // Fetch all reports that are due today
      const { data: reports, error } = await supabase
        .from("reports")
        .select("report_id, description, barangay_id")
        .eq("report_deadline", todayStr); // only reports due today

      /*   const { data: reports, error } = await supabase
        .from("reports")
        .select("report_id, description, barangay_id")
        .eq("report_deadline", tomorrowStr); // only reports due today
 */ //for tomorrow reminders final code

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
        }); //improve this in meeting

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
