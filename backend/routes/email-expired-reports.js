import supabase from '../supabaseClient.js';
// import { transporter } from '../backend-utils/mailer.js';
import { sendEmail } from '../backend-utils/mailer.js';
import fs from 'fs/promises';
import path from 'path';

async function buildReportHtml(report) {
  // Fetch related info
  const { data: user, error: userError } = await supabase
    .from('users')
    .select('name')
    .eq('user_id', report.user_id)
    .single();

  const { data: barangay, error: brgyError } = await supabase
    .from('barangays')
    .select('name, city, contact_email')
    .eq('barangay_id', report.barangay_id)
    .single();

  // Google Maps link
  let mapsLink = "";
  if (report.lat && report.lon) {
    mapsLink = `<a href="https://www.google.com/maps/search/?api=1&query=${report.lat},${report.lon}" target="_blank" style="color:#2e7d32;">View on Google Maps</a>`;
  }

  // Status badge
  let badgeText = "";
  let badgeClass = "";
  if (report.status === "expired") { badgeText = "Status: EXPIRED – Immediate Action Required"; badgeClass = "expired"; }
  else if (report.status === "pending") { badgeText = "Status: PENDING – Requires Follow-Up"; badgeClass = "pending"; }
  else if (report.status === "in_progress") { badgeText = "Status: IN PROGRESS – Ongoing"; badgeClass = "progress"; }
  else { badgeText = "Status: ON TRACK"; badgeClass = "ontrack"; }

  // Photos
  let photoUrlsHtml = "";
  if (Array.isArray(report.photo_urls)) {
    photoUrlsHtml = report.photo_urls.map(url =>
      `<img src="${url}" style="max-width:120px; max-height:120px; margin:4px; border-radius:8px;" alt="Report Photo" />`
    ).join("");
  }

  // Read and fill the template
  const templatePath = path.resolve(process.cwd(), '../lib/utils/email-templates/escalated-report.html');
  let template = await fs.readFile(templatePath, 'utf8');
  template = template
    .replace("${BADGE_TEXT}", badgeText)
    .replace("${BADGE_CLASS}", badgeClass)
    .replace("${REPORT_ID}", report.report_id)
    .replace("${REPORTER_NAME}", user?.name || "Unknown")
    .replace("${USER_ID}", report.user_id)
    .replace("${BARANGAY_NAME}", barangay?.name || "Unknown")
    .replace("${BARANGAY_CITY}", barangay?.city || "")
    .replace("${BARANGAY_CONTACT_EMAIL}", barangay?.contact_email || "")
    .replace("${DESCRIPTIVE_LOCATION}", report.descriptive_location || "")
    .replace("${GOOGLE_MAPS_LINK}", mapsLink)
    .replace("${CREATED_AT}", report.created_at)
    .replace("${REPORT_DEADLINE}", report.report_deadline)
    .replace("${STATUS}", report.status)
    .replace("${CATEGORY}", report.category)
    .replace("${PRIORITY}", report.priority)
    .replace("${HAZARDOUS}", report.hazardous ? "Yes" : "No")
    .replace("${ANONYMOUS}", report.anonymous ? "Yes" : "No")
    .replace("${DESCRIPTION}", report.description || "")
    .replace("${PHOTO_URLS_HTML}", photoUrlsHtml);

  return template;
}

export default async function emailExpiredReportsHandler(req, res) {
  try {
    console.log("emailExpiredReportsHandler called");
    const { data: reports, error } = await supabase
      .from('reports')
      .select('report_id, user_id, barangay_id, descriptive_location, lat, lon, description, photo_urls, category, priority, hazardous, anonymous, status, created_at, report_deadline')
      .lt('report_deadline', new Date().toISOString())
      .in('status', ['pending', 'in_progress']);

    if (error) throw error;
    if (!reports || reports.length === 0) {
      return res.status(200).json({ success: true, sent: 0, message: "No expired reports." });
    }

    let sent = 0;
    const recipient = 'landichoandrei29@gmail.com';

    for (const report of reports) {
      const subject = `URGENT: Report Expired (${report.report_id})`;
      const html = await buildReportHtml(report);

      await sendEmail({
        // from: process.env.EMAIL_USER,
        to: recipient,
        subject,
        html,
      });

      //for patching reposrts as escalted when emails are sent
      
      const { error: updateError } = await supabase
        .from('reports')
        .update({ status: 'escalated' })
        .eq('report_id', report.report_id);

      if (updateError) {
        console.error(`Failed to update report ${report.report_id}:`, updateError.message);
      }
      sent++;
    }

    return res.status(200).json({ success: true, sent });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}