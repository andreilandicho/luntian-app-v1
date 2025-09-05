import { z } from "zod";

const notifSchema = () => {
  const notifSubmissionSchema = z.object({
    reportID: z.string().uuid({ message: "Invalid UUID" }),
    createdAt: z.string().datetime({ message: "Invalid datetime format" }),
    title: z.string(),
    content: z.string(),
    role: z.string(),
    email: z.string().email({ message: "Invalid email address" }),
  });

  const notifStatusSchema = z.object({
    reportID: z.string().uuid({ message: "Invalid UUID" }),
    createdAt: z.string().datetime({ message: "Invalid datetime format" }),
    title: z.string(),
    content: z.string(),
    status: z.string(),
    role: z.string(),
    email: z.string().email({ message: "Invalid email address" }),
  });

  const notifAssignSchema = z.object({
    reportID: z.string().uuid({ message: "Invalid UUID" }),
    createdAt: z.string().datetime({ message: "Invalid datetime format" }),
    title: z.string(),
    content: z.string(),
    role: z.string(),
    email: z.string().email({ message: "Invalid email address" }),
  });

  const notifDueSchema = z.object({
    reportID: z.string().uuid({ message: "Invalid UUID" }),
    createdAt: z.string().datetime({ message: "Invalid datetime format" }),
    title: z.string(),
    content: z.string(),
    role: z.string(),
    email: z.string().email({ message: "Invalid email address" }),
  });
  return {
    notifSubmissionSchema: notifSubmissionSchema,
    notifStatusSchema: notifStatusSchema,
    notifAssignSchema: notifAssignSchema,
    notifDueSchem: notifDueSchema,
  };
};
/* 
async function sendNotification() {
  try {
    const response = await fetch("http://localhost:3000/api/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        reportID: uuidGen(),  // generate a UUID for this
        createdAt: new Date().toISOString(), // current datetime in ISO format
        title: "System Alert", //actual context should be placed here
        content: "A new issue has been detected in the monitoring system.", //actual context should be placed here
        role: user.role, // assuming you have user role context
        email: user.email, // assuming you have user email context
      }),
    });

    const data = await response.json();
    console.log("✅ Notification response:", data);
  } catch (err) {
    console.error("❌ Error sending notification:", err);
  }
}
*/
