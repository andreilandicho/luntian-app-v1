import cron from "node-cron";
import supabase from "../supabaseClient.js";
import { transporter } from "./mailer.js";

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
      const phTime = new Date(
        now.toLocaleString("en-US", { timeZone: "Asia/Manila" })
      );
      const todayStr = phTime.toISOString().split("T")[0]; // YYYY-MM-DD

      // Fetch all reports that are due today
      const { data: reports, error } = await supabase
        .from("reports")
        .select("report_id, title, description, report_deadline, barangay_id")
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
            <p><strong>Title:</strong> ${report.title}</p>
            <p><strong>Description:</strong> ${report.description}</p>
            <p><strong>Deadline:</strong> ${report.report_deadline}</p>
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
