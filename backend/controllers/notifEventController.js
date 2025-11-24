import nodemailer from "nodemailer";
import { createClient } from "@supabase/supabase-js";
import { DateTime } from "luxon";
import { sendEmail } from "../backend-utils/mailer.js";

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);

export async function eventNotifBarangay(req, res) {
  try {
    const { event_id } = req.body;

    // Fetch event details using event_id
    const { data: event, error: eventError } = await supabase
      .from("volunteer_events")
      .select("title, description, event_date, volunteers_needed, isPublic, barangay_id, created_by, photo_urls")
      .eq("event_id", event_id)
      .single();

    if (eventError || !event) {
      console.error("Error fetching event details:", eventError);
      return res.status(404).json({ error: "Event not found" });
    }

    // Fetch barangay contact email
    const { data: barangay, error: barangayError } = await supabase
      .from("barangays")
      .select("contact_email, name")
      .eq("barangay_id", event.barangay_id)
      .single();

    if (barangayError || !barangay) {
      console.error("Error fetching barangay email:", barangayError);
      return res.status(404).json({ error: "Barangay not found" });
    }

    // Fetch the barangay user (user with role = 'barangay' for this barangay)
    const { data: barangayUser, error: userError } = await supabase
      .from("users")
      .select("user_id, name")
      .eq("barangay_id", event.barangay_id)
      .eq("role", "barangay")
      .single();

    if (userError || !barangayUser) {
      console.error("Error fetching barangay user:", userError);
      return res.status(404).json({ error: "Barangay user not found" });
    }

    // Fetch event creator details
    const { data: creator, error: creatorError } = await supabase
      .from("users")
      .select("name, email")
      .eq("user_id", event.created_by)
      .single();

    if (creatorError || !creator) {
      console.error("Error fetching event creator details:", creatorError);
    }

    // Format the event date for display
    const eventDate = event.event_date ? 
      new Date(event.event_date).toLocaleString('en-US', {
        year: 'numeric', month: 'long', day: 'numeric',
        hour: '2-digit', minute: '2-digit'
      }) : 
      'Date not specified';

    // Send email notification
    await sendEmail({
      // from: process.env.EMAIL_USER,
      to: barangay.contact_email,
      subject: `New Event Proposal: ${event.title}`,
      html: `
        <h2>New Event Proposal</h2>
        <p>A new event has been proposed in your barangay and requires your approval.</p>
        
        <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <h3 style="color: #328E6E; margin-top: 0;">${event.title}</h3>
          <p><strong>Date:</strong> ${eventDate}</p>
          <p><strong>Volunteers Needed:</strong> ${event.volunteers_needed}</p>
          <p><strong>Event Type:</strong> ${event.isPublic ? 'Public' : 'Private'}</p>
          <p><strong>Description:</strong> ${event.description}</p>
          <p><strong>Proposed by:</strong> ${creator ? creator.name : 'Unknown'}</p>
        </div>
        
        <p>Please review this event proposal and update its approval status in the Luntian system.</p>
        <p>This event will not be visible to the public until approved.</p>
      `,
    });

    const phTime = DateTime.now().setZone("Asia/Manila").toISO();

    // Insert email log
    const { error: emailError } = await supabase.from("email").insert({
      created_at: phTime,
      title: `New Event Proposal: ${event.title}`,
      context: "New Event Proposal",
      content: `[For approval] New event proposal received: ${event.title}`,
      role: "barangay", //role of the email recepient
      email: barangay.contact_email,
      user_id: barangayUser.user_id,
      status: ["sent"],
    //   event_id
    });

    if (emailError) {
      console.error("Error inserting email log:", emailError);
    } else {
      console.log("Event notification email log saved to database");
    }

    return res.status(200).json({
      message: "Event notification email sent and log saved successfully",
      to: barangay.contact_email,
      event_id,
    });
  } catch (err) {
    console.error("Error sending event notification email:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
}

// Add this function for event approval notifications
export async function eventApprovalNotification(req, res) {
  try {
    const { event_id, approval_status, comment} = req.body;
    
    if (!event_id || !approval_status) {
      return res.status(400).json({ error: "Missing required parameters" });
    }

    // Fetch event details
    const { data: event, error: eventError } = await supabase
      .from("volunteer_events")
      .select("title, description, event_date, created_by, barangay_id")
      .eq("event_id", event_id)
      .single();

    if (eventError || !event) {
      console.error("Error fetching event details:", eventError);
      return res.status(404).json({ error: "Event not found" });
    }

    // Fetch event creator details
    const { data: creator, error: creatorError } = await supabase
      .from("users")
      .select("name, email")
      .eq("user_id", event.created_by)
      .single();

    if (creatorError || !creator) {
      console.error("Error fetching event creator:", creatorError);
      return res.status(404).json({ error: "Event creator not found" });
    }

    // Format the event date for display
    const eventDate = event.event_date ? 
      new Date(event.event_date).toLocaleString('en-US', {
        year: 'numeric', month: 'long', day: 'numeric',
        hour: '2-digit', minute: '2-digit'
      }) : 
      'Date not specified';
    
    // Determine email content based on approval status
    let emailSubject, emailContent, htmlContent;
    
    if (approval_status === 'approved') {
      emailSubject = `Event Approved: ${event.title}`;
      emailContent = `Your event "${event.title}" has been approved!`;
      htmlContent = `
        <h2 style="color: #328E6E;">Your Event Has Been Approved!</h2>
        <p>Good news! Your event proposal has been approved by the barangay.</p>
        
        <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <h3 style="margin-top: 0;">${event.title}</h3>
          <p><strong>Date:</strong> ${eventDate}</p>
          <p><strong>Description:</strong> ${event.description}</p>
        </div>
        
        <p>Your event will now be visible to community members. Thank you for your initiative!</p>
      `;
    } else if (approval_status === 'rejected') {
      emailSubject = `Event Rejected: ${event.title}`;
      emailContent = `Your event "${event.title}" was not approved.`;
      const rejectionReasonHtml = comment ? `
        <div style="background-color: #ffebee; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #d32f2f;">
          <h4 style="margin-top: 0; color: #d32f2f;">Reason for Rejection:</h4>
          <p style="white-space: pre-wrap;">${comment}</p>
        </div>
      ` : '';
      
      htmlContent = `
        <h2 style="color: #d32f2f;">Event Not Approved</h2>
        <p>We regret to inform you that your event proposal was not approved by the barangay.</p>
        
        <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <h3 style="margin-top: 0;">${event.title}</h3>
          <p><strong>Date:</strong> ${eventDate}</p>
          <p><strong>Description:</strong> ${event.description}</p>
        </div>
        
        ${rejectionReasonHtml}
        
        <p>Please contact your barangay office for more information or to discuss how to modify your event proposal.</p>
      `;
    } else {
      return res.status(400).json({ error: "Invalid approval status" });
    }

    // Send email notification to event creator
    await sendEmail({
      //from: process.env.EMAIL_USER,
      to: creator.email,
      subject: emailSubject,
      html: htmlContent,
    });

    const phTime = DateTime.now().setZone("Asia/Manila").toISO();

    // Log the email in the database
    const { error: emailError } = await supabase.from("email").insert({
    //   event_id, di ko pwede ilagay to sa emails table gawa report id ang andon
      user_id: event.created_by,
      title: emailSubject,
      content: emailContent,
      role: "citizen",
      email: creator.email,
      status: ["sent"],
      created_at: phTime,
      context: `event_${approval_status}`, //either accepted or rejected
    });

    if (emailError) {
      console.error("Error inserting email log:", emailError);
    }

    return res.status(200).json({
      message: `Event ${approval_status} notification sent successfully`,
      to: creator.email,
      event_id,
    });
  } catch (err) {
    console.error(`Error sending event ${req.body.approval_status} notification:`, err);
    return res.status(500).json({ error: "Internal server error" });
  }
}
