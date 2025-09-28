import cron from "node-cron";
import supabase from "../../backend/supabaseClient.js";
import { transporter } from "./mailer.js";
import { DateTime } from "luxon";
// Runs every 5 minutes in Philippine Time
cron.schedule(
  "0 0 * * *", // Every day at 00:00 (midnight)
  async () => {
    console.log(
    "⏰ Running due-date reminder job daily at midnight (PH time)..."
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
        .select("report_id, description, barangay_id, user_id") // add user_id here
        .eq("report_deadline", todayStr);

      /*   const { data: reports, error } = await supabase
        .from("reports")
        .select("report_id, description, barangay_id")
        .eq("report_deadline", tomorrowStr); // only reports due today
 */ //for tomorrow reminders final code

      if (error) throw error;

      for (const report of reports) {
        const { data: barangay, error: barangayError } = await supabase
          .from("barangays")
          .select("contact_email, user_id") //  add user_id here
          .eq("barangay_id", report.barangay_id)
          .single();

        if (barangayError || !barangay) {
          console.error(
            `Error fetching barangay details for report ${report.report_id}:`,
            barangayError
          );
          continue;
        }

        await transporter.sendMail({
          from: process.env.EMAIL_USER,
          to: barangay.contact_email,
          subject: `Reminder: Report Due Today (${report.report_id})`,
          html: `
        <h3>Reminder: Report Due Today</h3>
        <p><strong>Report ID:</strong> ${report.report_id}</p>
        <p><strong>Description:</strong> ${report.description}</p>
        `,
        });

        console.log(`✅ Reminder sent for report ${report.report_id}`);

        const { error: emailError } = await supabase.from("email").insert([
          {
            report_id: report.report_id,
            user_id: barangay.user_id, // fetched from barangays table
            title: "Report Due Reminder",
            content: `Report "${report.description}" is due today.`,
            email: barangay.contact_email,
            role: "barangay",
            created_at: DateTime.now().setZone("Asia/Manila").toISO(),
            context: "due date reminder",
          },
        ]);

        if (emailError) {
          console.error("❌ Error inserting email log:", emailError);
        } else {
          console.log(
            `📝 Logged reminder email for report ${report.report_id}`
          );
        }
      }
    } catch (err) {
      console.error("🔥 Cron job failed:", err);
    }
  },
  {
    timezone: "Asia/Manila", // Set timezone explicitly
  }
);