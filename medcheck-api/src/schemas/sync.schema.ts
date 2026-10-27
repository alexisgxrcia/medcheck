import { z } from "zod";

const medicationSchema = z.object({
	client_id: z.number(),
	remote_id: z.string().nullable(),
	name: z.string().min(1),
	dosage: z.string().nullable(),
	notes: z.string().nullable(),
	start_date: z.string().nullable(),
	end_date: z.string().nullable(),
	archived_at: z.string().nullable(),
	deleted_at: z.string().nullable(),
	created_at: z.string(),
	updated_at: z.string(),
});

const scheduleSchema = z.object({
	client_id: z.number(),
	remote_id: z.string().nullable(),
	medication_client_id: z.number(),
	medication_remote_id: z.string().nullable(),
	frequency_type: z.string(),
	time_of_day: z.string().nullable(),
	days_of_week: z.array(z.number()),
	interval_hours: z.number().nullable(),
	interval_days: z.number().nullable(),
	deleted_at: z.string().nullable(),
	created_at: z.string(),
	updated_at: z.string(),
});

const intakeSchema = z.object({
	client_id: z.number(),
	remote_id: z.string().nullable(),
	medication_client_id: z.number(),
	medication_remote_id: z.string().nullable(),
	scheduled_time: z.string(),
	taken_at: z.string().nullable(),
	status: z.enum(["taken", "missed", "skipped"]),
	source: z.enum(["manual", "notification", "auto"]),
	deleted_at: z.string().nullable(),
	created_at: z.string(),
	updated_at: z.string(),
});

export const syncPushSchema = z.object({
	last_synced_at: z.string().nullable(),
	changes: z.object({
		medications: z.array(medicationSchema).default([]),
		schedules: z.array(scheduleSchema).default([]),
		intakes: z.array(intakeSchema).default([]),
	}),
});
