import { z } from "zod";

export const notifSchema = z.object({
  reportID: z.string().uuid({ message: "Invalid UUID" }),
  createdAt: z.string().datetime({ message: "Invalid datetime format" }),
  title: z.string(),
  content: z.string(),
  role: z.string(),
  email: z.string().email({ message: "Invalid email address" }),
  status: z.array(z.string()).nullable().optional(),
});
