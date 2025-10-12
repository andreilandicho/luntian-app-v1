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

import nodemailer from "nodemailer";
import { createClient } from "@supabase/supabase-js";
import { DateTime } from "luxon";
import path from "path";
import fs from "fs";

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

//
export async function reportNotifBarangay(req, res) {
  try {
    const { report_id } = req.body;

    // Fetch report details using report_id
    const { data: report, error: reportError } = await supabase
      .from("reports")
      .select("description, category, priority, hazardous, lat, lon, user_id, report_id, barangay_id")
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
      .single(); // This should return only one record

    if (userError || !barangayUser) {
      console.error("Error fetching barangay user:", userError);
      return res.status(404).json({ error: "Barangay user not found" });
    }

    // Send email
    const templatePath = path.join(process.cwd(), "../lib/utils/email-templates/report-barangay.html");
    let htmlTemplate = fs.readFileSync(templatePath, "utf8");

    htmlTemplate = htmlTemplate
      .replace("${report.report_id}", report.report_id)
      .replace("${report.description}", report.description)
      .replace("${report.category}", report.category)
      .replace("${report.priority}", report.priority)
      .replace("${report.hazardous}", report.hazardous)
      .replace("${report.deadline}", report.deadline)
      .replace("${report.lat}", report.lat)
      .replace("${report.lon}", report.lon)
      .replace("${report.photo_urls_html}", report.photo_urls_html || "");

    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: barangay.contact_email,
      subject: `New Cleanliness Report: ${report.title}`,
      html: htmlTemplate,
    });

    console.log("Email sent successfully to:", barangay.contact_email);

    const phTime = DateTime.now().setZone("Asia/Manila").toISO();

    // Insert email log with the correct barangay user_id
    const { error: emailError } = await supabase.from("email").insert({
      report_id,
      user_id: barangayUser.user_id, // Correct user_id from users table
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

    const templatePath = path.join(process.cwd(), "../lib/utils/email-templates/official-assignment.html");
    const htmlTemplate = fs.readFileSync(templatePath, "utf8");

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

      const filledTemplate = htmlTemplate
        .replace(/\$\{report\.report_id\}/g, report.report_id)
        .replace(/\$\{report\.title\}/g, report.title || "N/A")
        .replace(/\$\{report\.description\}/g, report.description || "No description provided.")
        .replace(/\$\{report\.category\}/g, report.category || "Uncategorized")
        .replace(/\$\{report\.priority\}/g, report.priority || "Normal")
        .replace(/\$\{report\.hazardous\}/g, report.hazardous || "No")
        .replace(/\$\{report\.deadline\}/g, report.deadline || "Not set")
        .replace(/\$\{report\.lat\}/g, report.lat || "0")
        .replace(/\$\{report\.lon\}/g, report.lon || "0")
        .replace(/\$\{report\.photo_urls_html\}/g, report.photo_urls_html || "");

      await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: official.email,
        subject: `Official Assignment: ${report.title || "New Report"}`,
        html: filledTemplate,
      });

      console.log(`📧 Email sent successfully to ${official.email}`);

      // ✅ Move email log here
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
          created_at: new Date().toISOString(),
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
          title: "Report Resolved!",
          content: `Your report "${report.description}" has been resolved.`,
          role: "citizen",
          email: user.email,
          status: ["sent"],
          created_at: new Date().toISOString(),
          context: "report status change",
        },
      ]);

      if (emailError) {
        console.error("❌ Error inserting email log:", emailError);
      }

      // ✅ Load and use HTML template
      const templatePath = path.resolve(process.cwd(), "../lib/utils/email-templates/report-resolved.html");
      let template = await fs.readFileSync(templatePath, "utf8");

      template = template
        .replace(/\$\{REPORTER_NAME\}/g, user.name || "Citizen")
        .replace(/\$\{REPORT_ID\}/g, report.report_id)
        .replace(/\$\{DESCRIPTION\}/g, report.description || "No description provided.")
        .replace(/\$\{RESOLVED_AT\}/g, new Date().toLocaleString("en-PH", { dateStyle: "medium", timeStyle: "short" }))

      await transporter.sendMail({
        from: process.env.EMAIL_USER,
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

// async function dueDateReminder(req) {
// this is created on the utils since its cron job can be created here but the source of the cron job
//files might make it harder for adjustment going back and forth on the files