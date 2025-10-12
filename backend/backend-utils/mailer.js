//not supported by railway
// import nodemailer from "nodemailer";

// export const transporter = nodemailer.createTransport({
//   service: "gmail",
//   auth: {
//     user: process.env.EMAIL_USER,
//     pass: process.env.EMAIL_PASS,
//   },
// });
import sgMail from "@sendgrid/mail";

// Set your SendGrid API key from environment variables
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

// Example function to send email
export async function sendEmail({ to, subject, text, html }) {
  const msg = {
    to,
    from: process.env.EMAIL_USER, // must be a verified sender in SendGrid
    subject,
    text,
    html,
  };
  await sgMail.send(msg);
}