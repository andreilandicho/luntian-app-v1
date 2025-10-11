//role hierarchy so that i can keep using one controller design
// citizen report with the designated barangay this is for report sent to (barangay official)
// report tagged for designated official assignment task assigned via barangay itself
// citizen status change
// due date

//the following should have a unique json body or columns that would let the controller hit
// whether which is which

//4 controllers:

//1. citizen report submission with barangay emailer
//2. official assignment to barangay emailer
//3. citizen status change emailer also with 1 once the status is met
//4. due date emailer to barangay and official

// import nodemailer from "nodemailer";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs/promises";
import supabase from '../supabaseClient.js';
import { sendEmail } from "..backend-utils/mailer.js";
import { DateTime } from "luxon";

// const transporter = nodemailer.createTransport({
//   service: "gmail",
//   auth: {
//     user: process.env.EMAIL_USER,
//     pass: process.env.EMAIL_PASS,
//   },
// });

//


// Helper to build the HTML content from template and report data
async function buildReportHtml(report) {
  const __dirname = path.dirname(fileURLToPath(import.meta.url));
  const templatePath = path.resolve(__dirname, "./email-templates/report-submission.html");
  let template = await fs.readFile(templatePath, "utf8");

  // Prepare variables for template
  let mapsLink = "";
  if (report.lat && report.lon) {
    mapsLink = `<a href="https://www.google.com/maps/search/?api=1&query=${report.lat},${report.lon}" target="_blank" style="color:#2e7d32;">View on Google Maps</a>`;
  }

  let photoUrlsHtml = "";
  if (Array.isArray(report.photo_urls)) {
    photoUrlsHtml = report.photo_urls.map(url =>
      `<img src="${url}" style="max-width:120px; max-height:120px; margin:4px; border-radius:8px;" alt="Report Photo" />`
    ).join("");
  }

  let badgeText = "";
  let badgeClass = "";
  if (report.status === "expired") { badgeText = "Status: EXPIRED – Immediate Action Required"; badgeClass = "expired"; }
  else if (report.status === "pending") { badgeText = "Status: PENDING – Requires Follow-Up"; badgeClass = "pending"; }
  else if (report.status === "in_progress") { badgeText = "Status: IN PROGRESS – Ongoing"; badgeClass = "progress"; }
  else { badgeText = "Status: ON TRACK"; badgeClass = "ontrack"; }

  // Additional template variables
  const createdAt = DateTime.fromISO(report.created_at).setZone("Asia/Manila").toFormat("yyyy-MM-dd HH:mm");
  const reportDeadline = report.report_deadline ? DateTime.fromISO(report.report_deadline).setZone("Asia/Manila").toFormat("yyyy-MM-dd HH:mm") : "";
  const anonymous = report.anonymous ? "Yes" : "No";
  const status = report.status;

  template = template
    .replace("${BADGE_TEXT}", badgeText)
    .replace("${BADGE_CLASS}", badgeClass)
    .replace("${REPORT_ID}", report.report_id)
    .replace("${DESCRIPTIVE_LOCATION}", report.descriptive_location || "")
    .replace("${CATEGORY}", report.category)
    .replace("${PRIORITY}", report.priority)
    .replace("${HAZARDOUS}", report.hazardous ? "Yes" : "No")
    .replace("${GOOGLE_MAPS_LINK}", mapsLink)
    .replace("${DESCRIPTION}", report.description || "")
    .replace("${PHOTO_URLS_HTML}", photoUrlsHtml)
    .replace("${ANONYMOUS}", anonymous)
    .replace("${CREATED_AT}", createdAt)
    .replace("${REPORT_DEADLINE}", reportDeadline)
    .replace("${STATUS}", status);

  return template;
}

export async function reportNotifBarangay(req, res) {
  try {
    const { report_id } = req.body;

    // Fetch report details using report_id
    const { data: report, error: reportError } = await supabase
      .from("reports")
      .select("report_id, user_id, barangay_id, descriptive_location, lat, lon, description, photo_urls, category, priority, hazardous, anonymous, status, created_at, report_deadline")
      .eq("report_id", report_id)
      .single();

    if (reportError || !report) {
      console.error("Error fetching report details:", reportError);
      return res.status(404).json({ error: "Report not found" });
    }

    // Fetch barangay contact email
    const { data: barangay, error: barangayError } = await supabase
      .from("barangays")
      .select("contact_email")
      .eq("barangay_id", report.barangay_id)
      .single();

    if (barangayError || !barangay) {
      console.error("Error fetching barangay email:", barangayError);
      return res.status(404).json({ error: "Barangay not found" });
    }

    // Fetch the barangay user (user with role = 'barangay' for this barangay)
    const { data: barangayUser, error: userError } = await supabase
      .from("users")
      .select("user_id")
      .eq("barangay_id", report.barangay_id)
      .eq("role", "barangay")
      .single();

    if (userError || !barangayUser) {
      console.error("Error fetching barangay user:", userError);
      return res.status(404).json({ error: "Barangay user not found" });
    }

    // Build the HTML content using template
    const html = await buildReportHtml(report);

    // Send email
    await sendEmail({
      to: barangay.contact_email,
      subject: "New Report Submission!",
      html: html,
    });

    console.log("Email sent successfully to:", barangay.contact_email);

    const phTime = DateTime.now().setZone("Asia/Manila").toISO();

    // Insert email log with the correct barangay user_id
    const { error: emailError } = await supabase.from("email").insert({
      report_id,
      user_id: barangayUser.user_id,
      title: "New Report Submission",
      content: `New report received: ${report.description}`,
      role: "barangay",
      email: barangay.contact_email,
      status: ["sent"],
      created_at: phTime,
      context: "barangay notification",
    });

    if (emailError) {
      console.error("Error inserting email log:", emailError);
    } else {
      console.log("Email log saved to database");
    }

    return res.status(200).json({
      message: "Email sent and log saved successfully",
      to: barangay.contact_email,
      report_id,
    });
  } catch (err) {
    console.error("Error sending report email:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
}
export async function officialAssignment(req, res) {
  const { report_id } = req.body;

  try {
    const { data: assignments, error: assignError } = await supabase
      .from("report_assignments")
      .select("official_id")
      .eq("report_id", report_id);

    if (assignError || !assignments || assignments.length === 0) {
      console.error("❌ No officials assigned:", assignError);
      return res
        .status(404)
        .json({ error: "No officials assigned to this report" });
    }

    const { data: report, error: reportError } = await supabase
      .from("reports")
      .select("*")
      .eq("report_id", report_id)
      .single();

    if (reportError || !report) {
      console.error("❌ Report not found:", reportError);
      return res.status(404).json({ error: "Report not found" });
    }

    for (const assignment of assignments) {
      const { data: official, error: userError } = await supabase
        .from("users")
        .select("email")
        .eq("user_id", assignment.official_id)
        .single();

      if (userError || !official) {
        console.error(
          `❌ Official not found for ID ${assignment.official_id}:`,
          userError
        );
        continue;
      }

      const { error: emailError } = await supabase.from("email").insert([
        {
          report_id: report.report_id,
          user_id: assignment.official_id,
          title: "Report Assignment",
          content: `You've been assigned to report: ${report.description}`,
          email: official.email,
          role: "official",
          created_at: new Date().toISOString(),
          context: "official assignment",
        },
      ]);

      if (emailError) {
        console.error("❌ Error inserting into email log:", emailError);
      }

      await sendEmail({
        // from: process.env.EMAIL_USER,
        to: official.email,
        subject: `Official Notification: ${report.title}`,
        html: `
          <h3>You've been assigned a new report</h3>
          <p><strong>Report ID:</strong> ${report.report_id}</p>
          <p><strong>Title:</strong> ${report.title}</p>
          <p><strong>Description:</strong> ${report.description}</p>
          <p><strong>Category:</strong> ${report.category}</p>
          <p><strong>Priority:</strong> ${report.priority}</p>
          <p><strong>Hazardous:</strong> ${report.hazardous}</p>
          <p><strong>Deadline:</strong> ${report.deadline}</p>
          <p><strong>Location:</strong> 
            <a href="https://www.google.com/maps/?q=${report.lat},${report.lon}" target="_blank">
              View on Google Maps
            </a>
          </p>
        `,
      });

      console.log(`📧 Email sent successfully to ${official.email}`);
    }

    return res.status(200).json({
      message: "Emails sent to all assigned officials",
      report_id,
    });
  } catch (error) {
    console.error("❌ Error in officialAssignment:", error.message);
    return res.status(500).json({ error: "Internal server error" });
  }
}

export async function reportStatusChange(req, res) {
  const { report_id, newStatus } = req.body;

  try {
    const { data: report, error: reportError } = await supabase
      .from("reports")
      .select("status, user_id, description")
      .eq("report_id", report_id)
      .single();

    if (reportError || !report) {
      console.error("❌ Report not found:", reportError);
      return res.status(404).json({ error: "Report not found" });
    }

    if (newStatus !== report.status) {
      await supabase
        .from("reports")
        .update({ status: newStatus })
        .eq("report_id", report_id);
    } else {
      console.log(`ℹ️ No change. Status is already "${newStatus}"`);
      return res.status(200).json({ message: "No status change applied" });
    }

    const { error: updateError } = await supabase
      .from("reports")
      .update({ status: newStatus })
      .eq("report_id", report_id);

    if (updateError) {
      console.error("❌ Failed to update report status:", updateError);
      return res.status(400).json({ error: "Invalid status value" });
    }

    const { data: user, error: userError } = await supabase
      .from("users")
      .select("email")
      .eq("user_id", report.user_id)
      .single();

    if (userError || !user) {
      console.error("❌ User not found for report:", userError);
      return res.status(404).json({ error: "User not found" });
    }

    if (newStatus === "resolved" && report.status !== "resolved") {
      // Insert into email log
      const { error: emailError } = await supabase.from("email").insert([
        {
          report_id,
          user_id: report.user_id,
          title: "Report Solved", // required for populating so it doesnt go null and break
          content: `Your report "${report.description}" has been solved. Open Luntian to view solutions. Please rate the submitted solutions so that we can improve our service.`, // required same here
          role: "citizen", // role like you did with barangay/official
          email: user.email,
          status: ["sent"],
          created_at: new Date().toISOString(),
          context: "report status change",
        },
      ]);

      if (emailError) {
        console.error("❌ Error inserting email log:", emailError);
      }

      // Send notification email
      await sendEmail({
        // from: process.env.EMAIL_USER,
        to: user.email,
        subject: `Your Report Has Been Approved`,
        html: `
          <h3>Good news!</h3>
          <p>Your report has been approved.</p>
          <p><strong>Report ID:</strong> ${report_id}</p>
          <p><strong>Description:</strong> ${report.description}</p>
        `,
      });

      console.log(`📨 Approval email sent to: ${user.email}`);
    } else {
      console.log(
        `ℹ️ No email sent. Status changed from ${report.status} to ${newStatus}`
      );
    }

    return res.status(200).json({ message: "Report status processed" });
  } catch (error) {
    console.error("🔥 Error in reportStatusChange:", error.message);
    return res.status(500).json({ error: "Internal server error" });
  }
}

// async function dueDateReminder(req) {
// this is created on the utils since its cron job can be created here but the source of the cron job
//files might make it harder for adjustment going back and forth on the files