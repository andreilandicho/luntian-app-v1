import { notifSchema } from "../models/notificationSchema.js";
import nodemailer from "nodemailer";
import { createClient } from "@supabase/supabase-js";
import { Request, Response } from "express";

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER, // created email for this line
    pass: process.env.EMAIL_PASS, // created email for this line
  },
});

export const createNotifSubmission = async (req, res) => {
  const validation = notifSchema.notifSubmissionSchema.safeParse(req.body);

  const data = validation.data;

  if (data.role !== "Barangay Official") {
    return res.status(403).json({ message: "Forbidden" });
  }
  if (!validation.success) {
    return res
      .status(400)
      .json({ message: validation.error.errors[0].message });
  }
  try {
    //Insert into Supabase
    const { error } = await supabase.from("notifications").insert([
      {
        report_id: data.reportID, // match your Supabase column name further meeting for this
        title: data.title,
      },
    ]);

    if (error) throw error;

    //  Send email code block
    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: data.email, // TODO: make this dynamic if needed
      subject: `New Notification: ${data.title}`, // Email subject
      text: `A new report has been submitted.\n\nReport ID: ${data.reportID}\nTitle: ${data.title}\n\nContent: ${data.content}`, // Email body
    });

    //  status response
    return res.status(201).json({
      message: "Notification created and email sent!",
      inserted: { reportID: data.reportID, title: data.title },
    });
  } catch (error) {
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};

export const createNotifStatus = async (req, res) => {
  const validation = notifSchema.notifStatusSchema.safeParse(req.body);

  const data = validation.data;

  if (data.role !== "Barangay Official") {
    return res.status(403).json({ message: "Forbidden" });
  }
  if (!validation.success) {
    return res
      .status(400)
      .json({ message: validation.error.errors[0].message });
  }
  try {
    //Insert into Supabase
    const { error } = await supabase.from("notifications").insert([
      {
        report_id: data.reportID, // match your Supabase column name further meeting for this
        title: data.title,
      },
    ]);

    if (error) throw error;

    //  Send email code block
    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: data.email, // TODO: make this dynamic if needed
      subject: `New Notification: ${data.title}`, // Email subject
      text: `A new report has been submitted.\n\nReport ID: ${data.reportID}\nTitle: ${data.title}\n\nContent: ${data.content}`, // Email body
    });

    //  status response
    return res.status(201).json({
      message: "Notification created and email sent!",
      inserted: { reportID: data.reportID, title: data.title },
    });
  } catch (error) {
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};

export const createNotifAssign = async (req, res) => {
  const validation = notifSchema.notifAssignSchema.safeParse(req.body);

  const data = validation.data;

  if (data.role !== "Barangay Official") {
    return res.status(403).json({ message: "Forbidden" });
  }
  if (!validation.success) {
    return res
      .status(400)
      .json({ message: validation.error.errors[0].message });
  }
  try {
    //Insert into Supabase
    const { error } = await supabase.from("notifications").insert([
      {
        report_id: data.reportID, // match your Supabase column name further meeting for this
        title: data.title,
      },
    ]);

    if (error) throw error;

    //  Send email code block
    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: data.email, // TODO: make this dynamic if needed
      subject: `New Notification: ${data.title}`, // Email subject
      text: `A new report has been submitted.\n\nReport ID: ${data.reportID}\nTitle: ${data.title}\n\nContent: ${data.content}`, // Email body
    });

    //  status response
    return res.status(201).json({
      message: "Notification created and email sent!",
      inserted: { reportID: data.reportID, title: data.title },
    });
  } catch (error) {
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};

export const createNotifDue = async (req, res) => {
  const validation = notifSchema.notifDueSchema.safeParse(req.body);

  if (!validation.success) {
    return res
      .status(400)
      .json({ message: validation.error.errors[0].message });
  }

  const data = validation.data;

  if (data.role !== "Barangay Official") {
    return res.status(403).json({ message: "Forbidden" });
  }

  try {
    // Insert immediately (when API is hit)
    const { error } = await supabase.from("notifications").insert([
      {
        report_id: data.reportID,
        title: data.title,
      },
    ]);

    if (error) throw error;

    // Send email immediately
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
  } catch (err) {
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};
