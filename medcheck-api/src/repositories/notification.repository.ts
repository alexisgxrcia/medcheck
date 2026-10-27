import { executeQuery } from "@/config/database";
import type { DeviceTokenRow, PendingCaregiverAlert } from "@/types";

export async function upsertDeviceToken(
  userId: string,
  token: string,
  platform: string,
): Promise<DeviceTokenRow> {
  const rows = await executeQuery<DeviceTokenRow>(
    `INSERT INTO device_tokens (user_id, token, platform, last_seen)
     VALUES ($1, $2, $3, NOW())
     ON CONFLICT (token) DO UPDATE
       SET user_id = $1, last_seen = NOW()
     RETURNING *`,
    [userId, token, platform],
  );
  return rows[0];
}

export async function deleteDeviceTokenByToken(token: string): Promise<void> {
  await executeQuery("DELETE FROM device_tokens WHERE token = $1", [token]);
}

export async function deleteDeviceTokensByUser(userId: string): Promise<void> {
  await executeQuery("DELETE FROM device_tokens WHERE user_id = $1", [userId]);
}

export async function findDeviceTokensByUser(userId: string): Promise<
  DeviceTokenRow[]
> {
  return executeQuery<DeviceTokenRow>(
    `SELECT *
     FROM device_tokens
     WHERE user_id = $1
     ORDER BY last_seen DESC, created_at DESC`,
    [userId],
  );
}

export async function findPendingCaregiverAlerts(): Promise<
  PendingCaregiverAlert[]
> {
  return executeQuery<PendingCaregiverAlert>(
    `WITH actual_pending AS (
        SELECT
          i.id AS intake_id,
          i.medication_id,
          m.name AS medication_name,
          i.scheduled_time,
          to_char(i.scheduled_time AT TIME ZONE u_patient.timezone, 'FMHH12:MI am') AS scheduled_time_display,
          i.status AS intake_status,
          i.user_id AS patient_id,
          u_patient.display_name AS patient_name,
          pc.caregiver_id,
          u_caregiver.display_name AS caregiver_name,
          u_caregiver.email AS caregiver_email,
          pc.notify_delay_min,
          NULL::text AS device_token
        FROM intakes i
        JOIN medications m ON m.id = i.medication_id AND m.deleted_at IS NULL
        JOIN patient_caregiver pc
          ON pc.patient_id = i.user_id
         AND pc.status = 'active'
         AND pc.notify_on_miss = true
        JOIN users u_patient ON u_patient.id = i.user_id
        JOIN users u_caregiver ON u_caregiver.id = pc.caregiver_id
        WHERE i.status != 'taken'
          AND i.deleted_at IS NULL
          AND i.scheduled_time + (pc.notify_delay_min || ' minutes')::interval < NOW()
          AND NOT EXISTS (
            SELECT 1 FROM notifications n
            WHERE n.intake_id = i.id
              AND n.user_id = pc.caregiver_id
              AND n.type = 'caregiver_alert'
          )
      ),
      expected_occurrences AS (
        SELECT
          NULL::uuid AS intake_id,
          m.id AS medication_id,
          m.name AS medication_name,
          ((((occ.local_date::date)::text || ' ' || s.time_of_day)::timestamp)
            AT TIME ZONE u_patient.timezone) AS scheduled_time,
          to_char(
            (((occ.local_date::date)::text || ' ' || s.time_of_day)::timestamp),
            'FMHH12:MI am'
          ) AS scheduled_time_display,
          'no_intake'::text AS intake_status,
          m.user_id AS patient_id,
          u_patient.display_name AS patient_name,
          pc.caregiver_id,
          u_caregiver.display_name AS caregiver_name,
          u_caregiver.email AS caregiver_email,
          pc.notify_delay_min,
          NULL::text AS device_token,
          s.frequency_type,
          s.interval_hours
        FROM medications m
        JOIN schedules s
          ON s.medication_id = m.id
         AND s.deleted_at IS NULL
        JOIN patient_caregiver pc
          ON pc.patient_id = m.user_id
         AND pc.status = 'active'
         AND pc.notify_on_miss = true
        JOIN users u_patient ON u_patient.id = m.user_id
        JOIN users u_caregiver ON u_caregiver.id = pc.caregiver_id
        CROSS JOIN LATERAL generate_series(
          (
            GREATEST(
              COALESCE(m.start_date, (NOW() AT TIME ZONE u_patient.timezone)::date - 120),
              (NOW() AT TIME ZONE u_patient.timezone)::date - 120
            )::timestamp
          ),
          (
            LEAST(
              COALESCE(m.end_date, (NOW() AT TIME ZONE u_patient.timezone)::date),
              (NOW() AT TIME ZONE u_patient.timezone)::date
            )::timestamp
          ),
          '1 day'::interval
        ) AS occ(local_date)
        WHERE m.deleted_at IS NULL
          AND m.archived_at IS NULL
          AND s.time_of_day IS NOT NULL
          AND s.frequency_type NOT IN ('prn', 'interval')
          AND (
            s.frequency_type = 'daily'
            OR (
              s.frequency_type = 'weekly'
              AND EXTRACT(DOW FROM occ.local_date::date)::int = ANY(s.days_of_week)
            )
            OR (
              s.frequency_type = 'everyXDays'
              AND occ.local_date::date >= COALESCE(
                m.start_date,
                (m.created_at AT TIME ZONE u_patient.timezone)::date
              )
              AND MOD(
                occ.local_date::date - COALESCE(
                  m.start_date,
                  (m.created_at AT TIME ZONE u_patient.timezone)::date
                ),
                GREATEST(COALESCE(s.interval_days, 1), 1)
              ) = 0
            )
          )
        UNION ALL
        SELECT
          NULL::uuid AS intake_id,
          m.id AS medication_id,
          m.name AS medication_name,
          (occ.local_scheduled AT TIME ZONE u_patient.timezone) AS scheduled_time,
          TO_CHAR(occ.local_scheduled, 'FMHH12:MI am') AS scheduled_time_display,
          'no_intake'::text AS intake_status,
          m.user_id AS patient_id,
          u_patient.display_name AS patient_name,
          pc.caregiver_id,
          u_caregiver.display_name AS caregiver_name,
          u_caregiver.email AS caregiver_email,
          pc.notify_delay_min,
          NULL::text AS device_token,
          s.frequency_type,
          s.interval_hours
        FROM medications m
        JOIN schedules s
          ON s.medication_id = m.id
         AND s.deleted_at IS NULL
        JOIN patient_caregiver pc
          ON pc.patient_id = m.user_id
         AND pc.status = 'active'
         AND pc.notify_on_miss = true
        JOIN users u_patient ON u_patient.id = m.user_id
        JOIN users u_caregiver ON u_caregiver.id = pc.caregiver_id
        CROSS JOIN LATERAL generate_series(
          (((COALESCE(
              m.start_date,
              (m.created_at AT TIME ZONE u_patient.timezone)::date
            )::text || ' ' || s.time_of_day)::timestamp)),
          LEAST(
            COALESCE(
              ((m.end_date::text || ' 23:59')::timestamp),
              (NOW() AT TIME ZONE u_patient.timezone)
            ),
            (NOW() AT TIME ZONE u_patient.timezone)
          ),
          (GREATEST(COALESCE(s.interval_hours, 1), 1)::text || ' hours')::interval
        ) AS occ(local_scheduled)
        WHERE m.deleted_at IS NULL
          AND m.archived_at IS NULL
          AND s.time_of_day IS NOT NULL
          AND s.frequency_type = 'interval'
      ),
      synthetic_pending AS (
        SELECT
          eo.intake_id,
          eo.medication_id,
          eo.medication_name,
          eo.scheduled_time,
          eo.scheduled_time_display,
          eo.intake_status,
          eo.patient_id,
          eo.patient_name,
          eo.caregiver_id,
          eo.caregiver_name,
          eo.caregiver_email,
          eo.notify_delay_min,
          eo.device_token
        FROM expected_occurrences eo
        WHERE (eo.scheduled_time + (eo.notify_delay_min || ' minutes')::interval) < NOW()
          AND NOT EXISTS (
            SELECT 1
            FROM intakes i
            WHERE i.medication_id = eo.medication_id
              AND i.user_id = eo.patient_id
              AND i.deleted_at IS NULL
              AND i.scheduled_time = eo.scheduled_time
          )
          AND NOT EXISTS (
            SELECT 1
            FROM notifications n
            WHERE n.medication_id = eo.medication_id
              AND n.user_id = eo.caregiver_id
              AND n.type = 'caregiver_alert'
              AND n.intake_id IS NULL
              AND n.created_at >= eo.scheduled_time + (eo.notify_delay_min || ' minutes')::interval
          )
      ),
      all_pending AS (
        SELECT * FROM actual_pending
        UNION ALL
        SELECT * FROM synthetic_pending
      ),
      ranked_pending AS (
        SELECT
          *,
          ROW_NUMBER() OVER (
            PARTITION BY caregiver_id, patient_id, medication_id
            ORDER BY scheduled_time DESC, intake_id DESC NULLS LAST
          ) AS row_num
        FROM all_pending
      )
      SELECT
        intake_id,
        medication_id,
        medication_name,
        scheduled_time,
        scheduled_time_display,
        intake_status,
        patient_id,
        patient_name,
        caregiver_id,
        caregiver_name,
        caregiver_email,
        notify_delay_min,
        device_token
      FROM ranked_pending
      WHERE row_num = 1`,
  );
}

export async function insertNotification(params: {
  userId: string;
  medicationId: string;
  intakeId: string | null;
  type: string;
  title: string;
  body: string;
  pushStatus: string;
}): Promise<string> {
  const rows = await executeQuery<{ id: string }>(
    `INSERT INTO notifications (user_id, medication_id, intake_id, type, title, body, push_status, push_sent_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, CASE WHEN $7 = 'sent' THEN NOW() ELSE NULL END)
     RETURNING id`,
    [
      params.userId,
      params.medicationId,
      params.intakeId,
      params.type,
      params.title,
      params.body,
      params.pushStatus,
    ],
  );
  return rows[0].id;
}

export async function markNotificationSent(notificationId: string): Promise<void> {
  await executeQuery(
    `UPDATE notifications SET push_status = 'sent', push_sent_at = NOW() WHERE id = $1`,
    [notificationId],
  );
}
