import cron from "node-cron";
import supabase from "../supabaseClient.js";
import { transporter } from "./mailer.js";
import { DateTime } from "luxon";

// Runs daily at 8:00 AM Philippine Time (better timing for business hours)
cron.schedule(
  "30 17 * * *", // Every day at 5:30 PM
  async () => {
    console.log("⏰ Running due-date reminder job at 5:30 (PH time)...");

    try {
      // Get today and tomorrow in PH time
      const now = DateTime.now().setZone("Asia/Manila");
      const todayStr = now.toFormat("yyyy-MM-dd");
      const tomorrowStr = now.plus({ days: 1 }).toFormat("yyyy-MM-dd");

      // Fetch all reports that are due today OR tomorrow (for early reminders)
      const { data: reports, error } = await supabase
        .from("reports")
        .select(`
          report_id, 
          description, 
          barangay_id,
          report_deadline,
          status
        `)
        .in("report_deadline", [todayStr, tomorrowStr])
        .in("status", ["pending", "in_progress"]); // Only active reports

      if (error) throw error;

      if (!reports || reports.length === 0) {
        console.log("✅ No reports due today or tomorrow. Job completed.");
        return;
      }

      console.log(`📋 Processing ${reports.length} due reports...`);

      // Batch process reports
      for (const report of reports) {
        try {
          const isDueToday = report.report_deadline === todayStr;
          const isDueTomorrow = report.report_deadline === tomorrowStr;

          // Fetch barangay and user data in parallel for better performance
          const [barangayResult, userResult] = await Promise.allSettled([
            supabase
              .from("barangays")
              .select("contact_email, name")
              .eq("barangay_id", report.barangay_id)
              .single(),
            supabase
              .from("users")
              .select("user_id, name")
              .eq("barangay_id", report.barangay_id)
              .eq("role", "barangay")
              .single()
          ]);

          // Handle barangay data
          if (barangayResult.status === 'rejected' || !barangayResult.value.data) {
            console.error(`❌ Error fetching barangay for report ${report.report_id}:`, barangayResult.reason);
            continue;
          }

          const barangay = barangayResult.value.data;

          // Handle user data
          let barangayUser = null;
          if (userResult.status === 'fulfilled' && userResult.value.data) {
            barangayUser = userResult.value.data;
          }

          if (!barangay.contact_email) {
            console.warn(`⚠️ No contact email for barangay ${barangay.name}`);
            continue;
          }

          // Prepare email content based on due date
          const subject = isDueToday 
            ? `URGENT: Report Due Today (${report.report_id})`
            : `Reminder: Report Due Tomorrow (${report.report_id})`;

          const urgencyText = isDueToday ? "TODAY" : "tomorrow";

          const html = `
            <h3>${isDueToday ? '🚨 URGENT: Report Due Today' : '📅 Reminder: Report Due Tomorrow'}</h3>
            <p><strong>Report ID:</strong> ${report.report_id}</p>
            <p><strong>Description:</strong> ${report.description}</p>
            <p><strong>Due Date:</strong> ${report.report_deadline}</p>
            <p><strong>Status:</strong> ${report.status}</p>
            <p>This report is due <strong>${urgencyText}</strong>. Please ensure it is addressed promptly.</p>
            ${isDueToday ? '<p style="color: #d32f2f; font-weight: bold;">This report is due TODAY and requires immediate attention.</p>' : ''}
          `;

          // Send email
          await transporter.sendMail({
            from: process.env.EMAIL_USER,
            to: barangay.contact_email,
            subject: subject,
            html: html,
          });

          console.log(`✅ ${isDueToday ? 'Urgent' : 'Reminder'} email sent for report ${report.report_id}`);

          // Log email in database if we have a user ID
          if (barangayUser) {
            const { error: emailError } = await supabase.from("email").insert({
              report_id: report.report_id,
              user_id: barangayUser.user_id,
              title: subject,
              content: `Report "${report.description}" is due ${urgencyText}. Current status: ${report.status}`,
              email: barangay.contact_email,
              role: "barangay",
              created_at: now.toISO(),
              context: `due_date_reminder_${isDueToday ? 'today' : 'tomorrow'}`,
              status: "sent"
            });

            if (emailError) {
              console.error("❌ Error inserting email log:", emailError);
            } else {
              console.log(`📝 Logged reminder email for report ${report.report_id}`);
            }
          }

        } catch (reportError) {
          console.error(`🔥 Failed to process report ${report.report_id}:`, reportError);
          // Continue with next report instead of stopping entire job
          continue;
        }
      }

      console.log(`🎉 Due date reminder job completed. Processed ${reports.length} reports.`);

    } catch (err) {
      console.error("🔥 Cron job failed:", err);
    }
  },
  {
    timezone: "Asia/Manila",
  }
);

// Optional: Add a more frequent "imminent deadline" checker for reports due in the next few hours
cron.schedule(
  "0 */6 * * *", // Every 6 hours
  async () => {
    console.log("⏰ Checking for reports due in the next 24 hours...");
    
    try {
      const now = DateTime.now().setZone("Asia/Manila");
      const next24Hours = now.plus({ hours: 24 }).toFormat("yyyy-MM-dd");
      
      // Similar logic but for reports due within 24 hours
      // You can implement this based on the same pattern above
      
    } catch (err) {
      console.error("🔥 Imminent deadline check failed:", err);
    }
  },
  {
    timezone: "Asia/Manila",
  }
);