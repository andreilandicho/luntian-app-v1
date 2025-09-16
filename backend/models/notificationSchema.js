import { z } from "zod";

export const notifSchema = {
  notifSubmissionSchema: z.object({
    reportID: z.string().uuid({ message: "Invalid UUID" }),
    createdAt: z.string().datetime({ message: "Invalid datetime format" }),
    title: z.string(),
    content: z.string(),
    role: z.string(),
    email: z.string().email({ message: "Invalid email address" }),
  }),

  notifStatusSchema: z.object({
    reportID: z.string().uuid({ message: "Invalid UUID" }),
    createdAt: z.string().datetime({ message: "Invalid datetime format" }),
    title: z.string(),
    content: z.string(),
    status: z.string(),
    role: z.string(),
    email: z.string().email({ message: "Invalid email address" }),
  }),

  notifAssignSchema: z.object({
    reportID: z.string().uuid({ message: "Invalid UUID" }),
    createdAt: z.string().datetime({ message: "Invalid datetime format" }),
    title: z.string(),
    content: z.string(),
    role: z.string(),
    email: z.string().email({ message: "Invalid email address" }),
  }),

  notifDueSchema: z.object({
    reportID: z.string().uuid({ message: "Invalid UUID" }),
    createdAt: z.string().datetime({ message: "Invalid datetime format" }),
    title: z.string(),
    content: z.string(),
    role: z.string(),
    email: z.string().email({ message: "Invalid email address" }),
  }),
};
