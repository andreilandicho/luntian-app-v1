import { notifSchema } from "../models/notificationSchema.js";
import nodemailer from "nodemailer";
import { createClient } from "@supabase/supabase-js";

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

// Fetch the user from Supabase

// 🔹 Shared handler
async function handleNotification(req, res, schema) {
  const validation = schema.safeParse(req.body);

  if (!validation.success) {
    return res.status(400).json({
      message: validation.error.errors[0].message,
    });
  }

  const data = validation.data;

  const { data: user, error: userError } = await supabase
    .from("users")
    .select("*")
    .eq("email", data.email)
    .single();

  if (userError || !user) {
    return res.status(404).json({ message: "User not found" });
  }

  if (user.role !== "official") {
    return res.status(403).json({ message: "Forbidden" });
  }

  try {
    // Insert into Supabase
    const { error } = await supabase.from("email").insert([
      {
        report_id: data.reportID,
        title: data.title,
        content: data.content,
        user_id: user.user_id,
        role: user.role,
        email: user.email,
      },
    ]);

    if (error) {
      console.error("Supabase insert error:", error);
      throw error;
    }

    // Send email
    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: data.email,
      subject: `New Notification: ${data.title}`,
      text: `A new report has been submitted.\n\nReport ID: ${data.reportID}\nTitle: ${data.title}\n\nContent: ${data.content}`,
    });

    return res.status(201).json({
      message: "Notification created and email sent!",
      inserted: { reportID: data.reportID, title: data.title },
    });
  } catch (error) {
    return res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
}

// 🔹 Exported controllers
export const createNotifSubmission = (req, res) =>
  handleNotification(req, res, notifSchema.notifSubmissionSchema);

export const createNotifStatus = (req, res) =>
  handleNotification(req, res, notifSchema.notifStatusSchema);

export const createNotifAssign = (req, res) =>
  handleNotification(req, res, notifSchema.notifAssignSchema);

export const createNotifDue = (req, res) =>
  handleNotification(req, res, notifSchema.notifDueSchema);
