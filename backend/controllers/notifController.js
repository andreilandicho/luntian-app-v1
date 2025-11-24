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
import { sendEmail } from "../backend-utils/mailer.js";
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
  const templatePath = path.resolve(__dirname, "../backend-utils/email-templates/report-submission.html");
                                                
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
  const { report_id } = req.body; // ✅ Add this line

  try {
    const { data: assignments, error: assignError } = await supabase
      .from("report_assignments")
      .select("official_id")
      .eq("report_id", report_id);

    if (assignError || !assignments?.length) {
      console.error("❌ No officials assigned:", assignError);
      return res.status(404).json({ error: "No officials assigned to this report" });
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

    const __dirname = path.dirname(fileURLToPath(import.meta.url));
    const templatePath = path.resolve(__dirname, "../backend-utils/email-templates/official-assignment.html");
                                                
    let template = await fs.readFile(templatePath, "utf8");

    // ✅ Build photo URLs HTML
    let photoUrlsHtml = "";
    if (Array.isArray(report.photo_urls)) {
      photoUrlsHtml = report.photo_urls.map(url =>
        `<img src="${url}" style="max-width:120px; max-height:120px; margin:4px; border-radius:8px;" alt="Report Photo" />`
      ).join("");
    }

    for (const assignment of assignments) {
      const { data: official, error: userError } = await supabase
        .from("users")
        .select("email")
        .eq("user_id", assignment.official_id)
        .single();

      if (userError || !official) {
        console.error(`❌ Official not found for ID ${assignment.official_id}:`, userError);
        continue;
      }

      // ✅ Fill template (use 'template' not 'htmlTemplate')
      const filledTemplate = template
        .replace(/\$\{report\.report_id\}/g, report.report_id)
        .replace(/\$\{report\.title\}/g, report.title || "N/A")
        .replace(/\$\{report\.description\}/g, report.description || "No description provided.")
        .replace(/\$\{report\.category\}/g, report.category || "Uncategorized")
        .replace(/\$\{report\.priority\}/g, report.priority || "Normal")
        .replace(/\$\{report\.hazardous\}/g, report.hazardous ? "Yes" : "No")
        .replace(/\$\{report\.deadline\}/g, report.report_deadline || "Not set")
        .replace(/\$\{report\.lat\}/g, report.lat || "0")
        .replace(/\$\{report\.lon\}/g, report.lon || "0")
        .replace(/\$\{report\.photo_urls_html\}/g, photoUrlsHtml);

      // ✅ Send email ONCE
      await sendEmail({
        to: official.email,
        subject: `Official Assignment: ${report.title || "New Report"}`,
        html: filledTemplate,
      });

      console.log(`📧 Email sent successfully to ${official.email}`);

      // ✅ Log email
      const phTime = DateTime.now().setZone("Asia/Manila").toISO();

      const { error: emailError } = await supabase.from("email").insert([
        {
          report_id: report.report_id,
          user_id: assignment.official_id,
          title: "Report Assignment",
          content: `You've been assigned to report: ${report.description}`,
          email: official.email,
          role: "official",
          status: ["sent"],
          created_at: phTime,
          context: "official assignment",
        },
      ]);

      if (emailError) {
        console.error("❌ Error inserting into email log:", emailError);
      }
    }

    return res.status(200).json({
      message: "Emails sent and logged for all assigned officials",
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
      .select("status, user_id, report_id, description")
      .eq("report_id", report_id)
      .single();

    if (reportError || !report) {
      console.error("❌ Report not found:", reportError);
      return res.status(404).json({ error: "Report not found" });
    }

    // ✅ Only update if status is different
    if (newStatus !== report.status) {
      const { error: updateError } = await supabase
        .from("reports")
        .update({ status: newStatus })
        .eq("report_id", report_id);

      if (updateError) {
        console.error("❌ Failed to update report status:", updateError);
        return res.status(400).json({ error: "Invalid status value" });
      }
    } else {
      console.log(`ℹ️ No change. Status is already "${newStatus}"`);
      // ❌ DON'T return here - continue to email logic!
      // return res.status(200).json({ message: "No status change applied" });
    }

    const { data: user, error: userError } = await supabase
      .from("users")
      .select("email, name")
      .eq("user_id", report.user_id)
      .single();

    if (userError || !user) {
      console.error("❌ User not found for report:", userError);
      return res.status(404).json({ error: "User not found" });
    }

    // ✅ Check if we should send email (status changed to resolved OR was already resolved but email not sent)
    if (newStatus === "resolved") {
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
        subject: "✅ Your Report Has Been Resolved",
        html: template,
      });


      console.log(`📨 Approval email sent to: ${user.email}`);
    } else {
      console.log(
        `ℹ️ No email sent. Status is ${newStatus}`
      );
    }

    return res.status(200).json({ message: "Report status processed" });
  } catch (error) {
    console.error("🔥 Error in reportStatusChange:", error.message);
    return res.status(500).json({ error: "Internal server error" });
  }
}

// Add this new function to your existing controller file
export async function notifyCitizenReportResolved(req, res) {
  const { report_id } = req.body;

  try {
    // Fetch report details
    const { data: report, error: reportError } = await supabase
      .from("reports")
      .select("report_id, user_id, description, category, status, created_at")
      .eq("report_id", report_id)
      .single();

    if (reportError || !report) {
      console.error("❌ Report not found:", reportError);
      return res.status(404).json({ error: "Report not found" });
    }

    // Check if report is actually resolved
    if (report.status !== "resolved") {
      return res.status(400).json({ 
        error: "Report is not resolved", 
        current_status: report.status 
      });
    }

    // Fetch citizen details
    const { data: citizen, error: citizenError } = await supabase
      .from("users")
      .select("email, name")
      .eq("user_id", report.user_id)
      .single();

    if (citizenError || !citizen) {
      console.error("❌ Citizen not found:", citizenError);
      return res.status(404).json({ error: "Citizen not found" });
    }

    // Load and fill the template
    const __dirname = path.dirname(fileURLToPath(import.meta.url));
    const templatePath = path.resolve(__dirname, "../backend-utils/email-templates/report-resolved.html");
    
    let template;
    try {
      template = await fs.readFile(templatePath, "utf8");
    } catch (error) {
      console.error("❌ Error loading resolved template:", error);
      // Fallback template
      template = `
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2>✅ Your Report Has Been Resolved!</h2>
          <p><strong>Report ID:</strong> \${report_id}</p>
          <p><strong>Description:</strong> \${description}</p>
          <p><strong>Category:</strong> \${category}</p>
          <p>Thank you for your contribution to making our community better!</p>
          <p>Please log in to Luntian to view the resolution details and provide feedback.</p>
        </div>
      `;
    }

    // Prepare template variables
    const resolveDate = DateTime.now().setZone("Asia/Manila").toFormat("yyyy-MM-dd HH:mm");
    const createdAt = DateTime.fromISO(report.created_at).setZone("Asia/Manila").toFormat("yyyy-MM-dd HH:mm");

    const html = template
      .replace(/\$\{report\.report_id\}/g, report.report_id)
      .replace(/\$\{report\.description\}/g, report.description || "No description provided")
      .replace(/\$\{report\.category\}/g, report.category || "Uncategorized")
      .replace(/\$\{resolve_date\}/g, resolveDate)
      .replace(/\$\{created_at\}/g, createdAt)
      .replace(/\$\{citizen\.name\}/g, citizen.name || "Valued Citizen");

    // Send email to citizen
    await sendEmail({
      to: citizen.email,
      subject: "✅ Your Report Has Been Resolved!",
      html: html,
    });

    console.log("📧 Resolution email sent to citizen:", citizen.email);

    // Log the email
    const phTime = DateTime.now().setZone("Asia/Manila").toISO();

    const { error: emailError } = await supabase.from("email").insert({
      report_id: report.report_id,
      user_id: report.user_id,
      title: "Report Resolved",
      content: `Your report "${report.description}" has been resolved. Thank you for your contribution.`,
      role: "citizen",
      email: citizen.email,
      status: ["sent"],
      created_at: phTime,
      context: "report_resolved",
    });

    if (emailError) {
      console.error("❌ Error inserting email log:", emailError);
    } else {
      console.log("✅ Email log saved for citizen notification");
    }

    return res.status(200).json({
      message: "Citizen notified of resolved report",
      report_id: report.report_id,
      citizen_email: citizen.email,
    });

  } catch (error) {
    console.error("🔥 Error in notifyCitizenReportResolved:", error.message);
    return res.status(500).json({ error: "Internal server error" });
  }
}

// Then modify your existing reportStatusChange function to call this new function:
export async function reportStatusChange(req, res) {
  const { report_id, newStatus } = req.body;

  try {
    const { data: report, error: reportError } = await supabase
      .from("reports")
      .select("status, user_id, report_id, description")
      .eq("report_id", report_id)
      .single();

    if (reportError || !report) {
      console.error("❌ Report not found:", reportError);
      return res.status(404).json({ error: "Report not found" });
    }

    // ✅ Only update if status is different
    if (newStatus !== report.status) {
      const { error: updateError } = await supabase
        .from("reports")
        .update({ status: newStatus })
        .eq("report_id", report_id);

      if (updateError) {
        console.error("❌ Failed to update report status:", updateError);
        return res.status(400).json({ error: "Invalid status value" });
      }
    }

    // ✅ If status changed to resolved, notify the citizen
    if (newStatus === "resolved") {
      // Call the new function to notify citizen
      await notifyCitizenReportResolved({ body: { report_id } }, {
        status: (code) => ({
          json: (data) => {
            if (code !== 200) {
              console.error("Failed to notify citizen:", data);
            }
          }
        })
      });

      // Also keep your existing email log for status change context
      const { data: user, error: userError } = await supabase
        .from("users")
        .select("email")
        .eq("user_id", report.user_id)
        .single();

      if (!userError && user) {
        const phTime = DateTime.now().setZone("Asia/Manila").toISO();
        
        await supabase.from("email").insert({
          report_id,
          user_id: report.user_id,
          title: "Report Status Updated",
          content: `Report status changed to ${newStatus}`,
          role: "citizen", 
          email: user.email,
          status: ["sent"],
          created_at: phTime,
          context: "status_change",
        });
      }
    }

    return res.status(200).json({ 
      message: "Report status updated and notifications sent",
      newStatus: newStatus 
    });

  } catch (error) {
    console.error("🔥 Error in reportStatusChange:", error.message);
    return res.status(500).json({ error: "Internal server error" });
  }
}
// async function dueDateReminder(req) {
// this is created on the utils since its cron job can be created here but the source of the cron job
//files might make it harder for adjustment going back and forth on the files