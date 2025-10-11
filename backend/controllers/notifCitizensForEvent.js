import nodemailer from "nodemailer";
import { createClient } from "@supabase/supabase-js";
import { DateTime } from "luxon";
import {sendEmail} from "../backend-utils/mailer.js";

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);

// const transporter = nodemailer.createTransport({
//   service: "gmail",
//   auth: {
//     user: process.env.EMAIL_USER,
//     pass: process.env.EMAIL_PASS,
//   },
// });
/**
 * This controller is inended for sending notifications to all citizens in a barangay when an event is approved. Only when an veent is approved should this be triggered.
 */
export async function notifyBarangayCitizens(req, res) {
  try {
    const { event_id, barangay_id } = req.body;
    
    if (!event_id || !barangay_id) {
      return res.status(400).json({ error: "Missing event_id or barangay_id" });
    }

    // Fetch event details
    const { data: event, error: eventError } = await supabase
      .from("volunteer_events")
      .select("title, description, event_date, photo_urls")
      .eq("event_id", event_id)
      .single();

    if (eventError || !event) {
      return res.status(404).json({ error: "Event not found" });
    }

    // Format event date
    const eventDate = event.event_date ? 
      new Date(event.event_date).toLocaleString('en-US', {
        year: 'numeric', month: 'long', day: 'numeric',
        hour: '2-digit', minute: '2-digit'
      }) : 'Date to be announced';

    // Get all citizens in this barangay
    const { data: citizens, error: citizensError } = await supabase
      .from("users")
      .select("user_id, name, email")
      .eq("barangay_id", barangay_id)
      .eq("role", "citizen");

    if (citizensError) {
      return res.status(500).json({ error: "Error fetching citizens" });
    }

    if (!citizens || citizens.length === 0) {
      return res.status(404).json({ error: "No citizens found in this barangay" });
    }

    // Prepare email HTML content
    const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #328E6E; margin-bottom: 20px;">New Event in Your Barangay!</h2>
        
        <div style="background-color: #f9f9f9; border-radius: 8px; padding: 20px; margin-bottom: 20px;">
          <h3 style="margin-top: 0;">${event.title}</h3>
          <p><strong>Date:</strong> ${eventDate}</p>
          <p>${event.description}</p>
        </div>
        
        ${event.photo_urls && event.photo_urls.length > 0 ? 
          `<div style="margin-bottom: 20px;">
            <img src="${event.photo_urls[0]}" style="max-width: 100%; border-radius: 8px;" alt="Event Image">
          </div>` : ''}
        
        <p>Join us for this exciting event! Open the Luntian app for more details and to register as a volunteer.</p>
        <p style="color: #666; font-size: 12px;">This is an automated message from your barangay's Luntian system.</p>
      </div>
    `;

    // Track successes and failures
    const results = {
      total: citizens.length,
      successful: 0,
      failed: 0
    };

    // Use Promise.all to send emails in parallel batches
    // Process in batches of 10 to avoid overwhelming the email server
    const batchSize = 10;
    const batches = Math.ceil(citizens.length / batchSize);
    const phTime = new Date().toISOString();

    for (let i = 0; i < batches; i++) {
      const start = i * batchSize;
      const end = Math.min(start + batchSize, citizens.length);
      const batch = citizens.slice(start, end);
      
      const batchPromises = batch.map(async (citizen) => {
        try {
          // Send email to each citizen
          await sendEmail({
            // from: process.env.EMAIL_USER,
            to: citizen.email,
            subject: `New Event: ${event.title}`,
            html: htmlContent,
          });

          // Log email in database
          await supabase.from("email").insert({
            // event_id,
            user_id: citizen.user_id,
            title: `New Event: ${event.title}`,
            content: `New event in your barangay: ${event.title}`,
            role: "citizen",
            email: citizen.email,
            status: ["sent"],
            created_at: phTime,
            context: "event_announcement",
          });
          
          results.successful++;
        } catch (error) {
          console.error(`Failed to send email to ${citizen.email}:`, error);
          results.failed++;
        }
      });
      
      await Promise.all(batchPromises);
      
      // Add a small delay between batches to avoid rate limiting
      if (i < batches - 1) {
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }

    return res.status(200).json({
      message: `Event notification processed for ${results.total} citizens`,
      results
    });
  } catch (err) {
    console.error("Error in batch notification:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
}