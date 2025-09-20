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

    //  Fetch report details using report_id
    const { data: report, error: reportError } = await supabase
      .from("reports")
      .select(
        " description, category, priority, hazardous, lat, lon, user_id, barangay_id"
      )
      .eq("report_id", report_id)
      .single();

    if (reportError || !report) {
      console.error("Error fetching report details:", reportError);
      return res.status(404).json({ error: "Report not found" });
    }

    const { data: barangay, error: barangayError } = await supabase
      .from("barangays")
      .select("contact_email")
      .eq("barangay_id", report.barangay_id)
      .single();

    if (barangayError || !barangay) {
      console.error("Error fetching barangay email:", barangayError);
      return res.status(404).json({ error: "Barangay not found" });
    }

    //  Send email
    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: barangay.contact_email,
      subject: "New Report Submission",
      html: `
        <h3>New Report Submitted</h3>
        <p><strong>Report ID:</strong> ${report_id}</p>
        <p><strong>Description:</strong> ${report.description}</p>
        <p><strong>Category:</strong> ${report.category}</p>
        <p><strong>Priority:</strong> ${report.priority}</p>
        <p><strong>Hazardous:</strong> ${report.hazardous}</p>
        <p><strong>Location:</strong> 
          <a href="https://www.google.com/maps/?q=${report.lat},${report.lon}" target="_blank">
            View on Google Maps
          </a>
        </p>
      `,
    });

    console.log(" Email sent successfully to:", barangay.contact_email);

    const phTime = DateTime.now().setZone("Asia/Manila").toISO();

    const { error: emailError } = await supabase.from("email").insert({
      report_id,
      user_id: report.user_id,
      title: "New Report Submission",
      content: `New report received: ${report.description}`,
      role: "barangay",
      email: barangay.contact_email,
      status: ["sent"],
      created_at: phTime,
    });

    if (emailError) {
      console.error("Error inserting email log:", emailError);
    } else {
      console.log(" Email log saved to database");
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
        },
      ]);

      if (emailError) {
        console.error("❌ Error inserting into email log:", emailError);
      }

      await transporter.sendMail({
        from: process.env.EMAIL_USER,
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
  const data = req.body;

  try {
    //  Fetch the report first to get its current status
    const { data: report, error: reportError } = await supabase
      .from("reports")
      .select("status")
      .eq("report_id", data.report_id)
      .single();

    if (reportError || !report) {
      console.error("❌ Report not found:", reportError);
      return;
    }

    //  Check transition: pending → in-progress
    if (report.status === "pending" && data.status === "in-progress") {
      // Log to email table
      const { error: emailError } = await supabase.from("email").insert([
        {
          report_id: data.report_id,
          title: data.title,
          content: data.content,
          email: data.email,
          status: data.status,
          created_at: new Date().toISOString(),
        },
      ]);

      if (emailError) {
        console.error(" Error inserting email log:", emailError);
      }

      // Send notification email
      await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: data.barangayEmail,
        subject: `Report Status Update: ${data.title}`,
        text: `Dear ${data.barangay},\n\nThe status of Report ID ${data.report_id}
         has changed from PENDING to IN-PROGRESS.\n\nTitle: ${data.title}\nContent: ${data.content}`,
      });

      console.log("📨 Status change email sent to:", data.barangayEmail);
    } else {
      console.log(
        `ℹ️ No email sent. Status changed from ${report.status} to ${data.status}`
      );
    }
  } catch (error) {
    console.error("Error in reportStatusChange:", error.message);
    return;
  }
}

// async function dueDateReminder(req) {
// this is created on the utils since its cron job can be created here but the source of the cron job
//files might make it harder for adjustment going back and forth on the files
