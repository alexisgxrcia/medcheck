import type { Request } from "express";

export interface AuthenticatedRequest extends Request {
  userId?: string;
}

export interface DeviceTokenRow {
  id: string;
  user_id: string;
  token: string;
  platform: string;
}

export interface PendingCaregiverAlert {
  intake_id: string | null;
  medication_id: string;
  medication_name: string;
  scheduled_time: string;
  scheduled_time_display: string;
  intake_status: string;
  patient_id: string;
  patient_name: string | null;
  caregiver_id: string;
  caregiver_name: string | null;
  caregiver_email: string;
  notify_delay_min: number;
  device_token: string | null;
}

export interface DbUser {
  id: string;
  email: string;
  display_name: string | null;
  provider: string;
  provider_id: string;
  timezone: string;
  role: string;
  birth_date: string | null;
  weight_kg: number | null;
  height_cm: number | null;
  notifications_enabled: boolean;
  miss_delay_min: number;
  dark_mode: boolean;
  created_at: string;
  updated_at: string;
}

export interface SyncPushMedication {
  client_id: number;
  remote_id: string | null;
  name: string;
  dosage: string | null;
  notes: string | null;
  start_date: string | null;
  end_date: string | null;
  archived_at: string | null;
  deleted_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface SyncPushSchedule {
  client_id: number;
  remote_id: string | null;
  medication_client_id: number;
  medication_remote_id: string | null;
  frequency_type: string;
  time_of_day: string | null;
  days_of_week: number[];
  interval_hours: number | null;
  interval_days: number | null;
  deleted_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface SyncPushIntake {
  client_id: number;
  remote_id: string | null;
  medication_client_id: number;
  medication_remote_id: string | null;
  scheduled_time: string;
  taken_at: string | null;
  status: "taken" | "missed" | "skipped";
  source: "manual" | "notification" | "auto";
  deleted_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface SyncPushPayload {
  last_synced_at: string | null;
  changes: {
    medications: SyncPushMedication[];
    schedules: SyncPushSchedule[];
    intakes: SyncPushIntake[];
  };
}

export interface IdMappings {
  medications: Record<string, string>;
  schedules: Record<string, string>;
  intakes: Record<string, string>;
}

export interface SyncResponse {
  changes: {
    medications: any[];
    schedules: any[];
    intakes: any[];
  };
  id_mappings: IdMappings;
  server_time: string;
}

export interface PendingNotification {
  user_id: string;
  timezone: string;
  medication_id: string;
  medication_name: string;
  time_of_day: string;
  caregiver_id: string;
  caregiver_email: string;
  notify_delay_min: number;
  intake_status: string | null;
  user_display_name: string | null;
}
