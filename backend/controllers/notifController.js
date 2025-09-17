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

  try {
    if (user.role === "official") {
      // 🔹 Insert into "email" table for officials
      const { error } = await supabase.from("email").insert([
        {
          report_id: data.reportID,
          title: data.title,
          content: data.content,
          user_id: user.user_id,
          role: user.role,
          email: user.email,
          status: data.status,
        },
      ]);

      if (error) throw error;

      // 🔹 Send email to official
      await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: data.email,
        subject: `📢 Official Notification: ${data.title}`,
        text: `Dear Official,\n\nA new report has been submitted.\n\nReport ID: ${data.reportID}\nTitle: ${data.title}\n\nContent: ${data.content}`,
      });
    } else if (user.role === "barangay") {
      // 🔹 Insert into a different table OR same table with different flags
      const { error } = await supabase.from("email").insert([
        {
          report_id: data.reportID,
          title: data.title,
          content: data.content,
          user_id: user.user_id,
          role: user.role,
          email: user.email,
          status: data.status,
        },
      ]);

      if (error) throw error;

      // 🔹 Send email to barangay
      await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: data.email,
        subject: `🏘️ Barangay Notification: ${data.title}`,
        text: `Dear Barangay Official,\n\nYou have a new report to review.\n\nReport ID: ${data.reportID}\nTitle: ${data.title}\n\nContent: ${data.content}`,
      });
    } else if (user.role === "citizen") {
      //needs to be in a different table
      // when creating content should have a pending value attach to it
      // only works when you have 2 values in the array and with the following condition

      if (data.status == "read") {
        const { error } = await supabase.from("email").insert([
          {
            report_id: data.reportID,
            title: data.title,
            content: data.content,
            user_id: user.user_id,
            role: user.role,
            email: user.email,
            status: data.status,
          },
        ]);

        if (error) throw error;

        await transporter.sendMail({
          from: process.env.EMAIL_USER,
          to: data.email,
          subject: `🏘️ citizen Notification: ${data.title}`,
          text: `Dear Barangay Official,\n\nYou have a new report to review.\n\nReport ID: ${data.reportID}\nTitle: ${data.title}\n\nContent: ${data.content}`,
        });
      }
    }

    return res.status(201).json({
      message: "Notification created and email sent!",
      inserted: { reportID: data.reportID, title: data.title, role: user.role },
    });
  } catch (error) {
    return res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
}

export const createNotifSubmission = (req, res) =>
  handleNotification(req, res, notifSchema);
