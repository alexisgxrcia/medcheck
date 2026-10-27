import type { PoolClient } from "pg";
import { withTransaction } from "@/config/database";

export async function findUserByEmail(email: string) {
  return withTransaction(async (client) => {
    const { rows } = await client.query(
      "SELECT id, email, display_name, role FROM users WHERE email = $1",
      [email],
    );
    return rows[0] ?? null;
  });
}

export async function findUserById(userId: string) {
  return withTransaction(async (client) => {
    const { rows } = await client.query(
      "SELECT id, email, display_name, role FROM users WHERE id = $1",
      [userId],
    );
    return rows[0] ?? null;
  });
}

export async function findExistingLink(
  client: PoolClient,
  patientId: string,
  caregiverId: string,
) {
  const { rows } = await client.query(
    `SELECT * FROM patient_caregiver
		 WHERE patient_id = $1 AND caregiver_id = $2 AND status != 'revoked'`,
    [patientId, caregiverId],
  );
  return rows[0] ?? null;
}

export async function insertLink(
  client: PoolClient,
  patientId: string,
  caregiverId: string,
  notifyOnMiss: boolean,
  notifyDelayMin: number,
  initiatedBy: string,
) {
  const { rows } = await client.query(
    `INSERT INTO patient_caregiver (patient_id, caregiver_id, status,
			permissions, notify_on_miss, notify_delay_min, initiated_by,
			created_at, updated_at, server_updated_at)
		VALUES ($1, $2, 'pending', '{view_history,view_medications}', $3, $4, $5, NOW(), NOW(), NOW())
		ON CONFLICT (patient_id, caregiver_id) DO UPDATE SET
			status = 'pending', notify_on_miss = $3, notify_delay_min = $4,
			initiated_by = $5, updated_at = NOW(), server_updated_at = NOW()
		RETURNING *`,
    [patientId, caregiverId, notifyOnMiss, notifyDelayMin, initiatedBy],
  );
  return rows[0];
}

export async function acceptLink(
  client: PoolClient,
  linkId: string,
  userId: string,
  notifyOnMiss?: boolean,
  notifyDelayMin?: number,
) {
  const setClauses = [
    "status = 'active'",
    "linked_at = NOW()",
    "updated_at = NOW()",
    "server_updated_at = NOW()",
  ];
  const params: (string | boolean | number)[] = [linkId, userId];
  let idx = 3;

  if (notifyOnMiss !== undefined) {
    setClauses.push(`notify_on_miss = $${idx}`);
    params.push(notifyOnMiss);
    idx++;
  }
  if (notifyDelayMin !== undefined) {
    setClauses.push(`notify_delay_min = $${idx}`);
    params.push(notifyDelayMin);
    idx++;
  }

  const { rows } = await client.query(
    `UPDATE patient_caregiver SET ${setClauses.join(", ")}
		 WHERE id = $1
		   AND (patient_id = $2 OR caregiver_id = $2)
		   AND status = 'pending'
		   AND (initiated_by IS NULL OR initiated_by IS DISTINCT FROM $2)
		 RETURNING id`,
    params,
  );
  if (!rows[0]) return null;

  const { rows: full } = await client.query(
    `SELECT pc.*,
			u_p.email        AS patient_email,
			u_p.display_name AS patient_name,
			u_c.email        AS caregiver_email,
			u_c.display_name AS caregiver_name
		FROM patient_caregiver pc
		JOIN users u_p ON pc.patient_id  = u_p.id
		JOIN users u_c ON pc.caregiver_id = u_c.id
		WHERE pc.id = $1`,
    [rows[0].id],
  );
  return full[0] ?? null;
}

export async function rejectLink(
  client: PoolClient,
  linkId: string,
  userId: string,
) {
  const { rows } = await client.query(
    `UPDATE patient_caregiver
		 SET status = 'revoked', updated_at = NOW(), server_updated_at = NOW()
		 WHERE id = $1
		   AND (patient_id = $2 OR caregiver_id = $2)
		   AND status = 'pending'
		   AND (initiated_by IS NULL OR initiated_by IS DISTINCT FROM $2)
		 RETURNING id`,
    [linkId, userId],
  );
  if (!rows[0]) return null;

  const { rows: full } = await client.query(
    `SELECT pc.*,
			u_p.email        AS patient_email,
			u_c.email        AS caregiver_email
		FROM patient_caregiver pc
		JOIN users u_p ON pc.patient_id  = u_p.id
		JOIN users u_c ON pc.caregiver_id = u_c.id
		WHERE pc.id = $1`,
    [rows[0].id],
  );
  return full[0] ?? null;
}

export async function getPendingLinksForUser(userId: string, role?: string) {
  return withTransaction(async (client) => {
    let roleFilter: string;

    if (role === "patient") {
      roleFilter = "pc.patient_id = $1";
    } else if (role === "caregiver") {
      roleFilter = "pc.caregiver_id = $1";
    } else {
      roleFilter = "(pc.patient_id = $1 OR pc.caregiver_id = $1)";
    }

    const { rows } = await client.query(
      `SELECT pc.*,
				u_patient.email  AS patient_email,
				u_patient.display_name  AS patient_name,
				u_caregiver.email AS caregiver_email,
				u_caregiver.display_name AS caregiver_name
			FROM patient_caregiver pc
			JOIN users u_patient  ON pc.patient_id  = u_patient.id
			JOIN users u_caregiver ON pc.caregiver_id = u_caregiver.id
			WHERE ${roleFilter}
			  AND pc.status = 'pending'
			  AND (pc.initiated_by IS NULL OR pc.initiated_by IS DISTINCT FROM $1)
			ORDER BY pc.created_at DESC`,
      [userId],
    );
    return rows;
  });
}

export async function getLinksForUser(userId: string) {
  return withTransaction(async (client) => {
    const { rows } = await client.query(
      `SELECT pc.*,
				u_patient.email AS patient_email,
				u_patient.display_name AS patient_name,
				u_caregiver.email AS caregiver_email,
				u_caregiver.display_name AS caregiver_name
			FROM patient_caregiver pc
			JOIN users u_patient ON pc.patient_id = u_patient.id
			JOIN users u_caregiver ON pc.caregiver_id = u_caregiver.id
			WHERE (pc.patient_id = $1 OR pc.caregiver_id = $1)
			  AND (
			    pc.status = 'active'
			    OR (pc.status = 'pending' AND pc.initiated_by = $1)
			  )
			ORDER BY pc.created_at DESC`,
      [userId],
    );
    return rows;
  });
}

export async function revokeLink(
  client: PoolClient,
  linkId: string,
  userId: string,
) {
  const { rows } = await client.query(
    `UPDATE patient_caregiver
		 SET status = 'revoked', updated_at = NOW(), server_updated_at = NOW()
		 WHERE id = $1
		   AND (
		     ((patient_id = $2 OR caregiver_id = $2) AND status = 'active')
		     OR (initiated_by = $2 AND status = 'pending')
		   )
		 RETURNING id`,
    [linkId, userId],
  );
  if (!rows[0]) return null;

  const { rows: full } = await client.query(
    `SELECT pc.*,
			u_p.email AS patient_email,
			u_p.display_name AS patient_name,
			u_c.email AS caregiver_email,
			u_c.display_name AS caregiver_name
		FROM patient_caregiver pc
		JOIN users u_p ON pc.patient_id = u_p.id
		JOIN users u_c ON pc.caregiver_id = u_c.id
		WHERE pc.id = $1`,
    [rows[0].id],
  );
  return full[0] ?? null;
}

export async function updateLinkSettings(
  client: PoolClient,
  linkId: string,
  userId: string,
  notifyOnMiss: boolean,
  notifyDelayMin: number,
) {
  const { rows } = await client.query(
    `UPDATE patient_caregiver
		 SET notify_on_miss = $3,
		     notify_delay_min = $4,
		     updated_at = NOW(),
		     server_updated_at = NOW()
		 WHERE id = $1
		   AND patient_id = $2
		   AND status = 'active'
		 RETURNING id`,
    [linkId, userId, notifyOnMiss, notifyDelayMin],
  );
  if (!rows[0]) return null;

  const { rows: full } = await client.query(
    `SELECT pc.*,
			u_p.email AS patient_email,
			u_p.display_name AS patient_name,
			u_c.email AS caregiver_email,
			u_c.display_name AS caregiver_name
		FROM patient_caregiver pc
		JOIN users u_p ON pc.patient_id = u_p.id
		JOIN users u_c ON pc.caregiver_id = u_c.id
		WHERE pc.id = $1`,
    [rows[0].id],
  );
  return full[0] ?? null;
}

export async function findActiveCaregiverLink(
  client: PoolClient,
  linkId: string,
  caregiverId: string,
) {
  const { rows } = await client.query(
    `SELECT * FROM patient_caregiver
		 WHERE id = $1
		   AND caregiver_id = $2
		   AND status = 'active'`,
    [linkId, caregiverId],
  );
  return rows[0] ?? null;
}

export async function getActiveCaregiverIdsByPatientId(
  client: PoolClient,
  patientId: string,
) {
  const { rows } = await client.query(
    `SELECT caregiver_id
		 FROM patient_caregiver
		 WHERE patient_id = $1
		   AND status = 'active'`,
    [patientId],
  );
  return rows.map((row) => row.caregiver_id as string);
}

export async function getPatientMedications(
  client: PoolClient,
  patientId: string,
) {
  const { rows } = await client.query(
    `SELECT m.*,
			COALESCE(
				json_agg(s.* ORDER BY s.created_at)
				FILTER (WHERE s.id IS NOT NULL AND s.deleted_at IS NULL),
				'[]'
			) AS schedules
		FROM medications m
		LEFT JOIN schedules s ON s.medication_id = m.id
		WHERE m.user_id = $1
		  AND m.deleted_at IS NULL
		  AND m.archived_at IS NULL
		GROUP BY m.id
		ORDER BY m.created_at DESC`,
    [patientId],
  );
  return rows;
}

export async function getPatientProfile(
  client: PoolClient,
  patientId: string,
) {
  const { rows } = await client.query(
    `SELECT id,
            email,
            display_name,
            timezone,
            birth_date,
            weight_kg,
            height_cm
       FROM users
      WHERE id = $1`,
    [patientId],
  );
  return rows[0] ?? null;
}

export async function getPatientMedicationById(
  client: PoolClient,
  patientId: string,
  medicationId: string,
) {
  const { rows } = await client.query(
    `SELECT m.*,
			COALESCE(
				json_agg(s.* ORDER BY s.created_at)
				FILTER (WHERE s.id IS NOT NULL AND s.deleted_at IS NULL),
				'[]'
			) AS schedules
		FROM medications m
		LEFT JOIN schedules s ON s.medication_id = m.id
		WHERE m.id = $1
		  AND m.user_id = $2
		  AND m.deleted_at IS NULL
		GROUP BY m.id`,
    [medicationId, patientId],
  );
  return rows[0] ?? null;
}

export async function insertPatientMedication(
  client: PoolClient,
  patientId: string,
  med: {
    name: string;
    dosage: string | null;
    notes: string | null;
    start_date: string | null;
    end_date: string | null;
  },
) {
  const { rows } = await client.query(
    `INSERT INTO medications (user_id, name, dosage, notes, start_date, end_date,
			created_at, updated_at, server_updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW(), NOW())
		RETURNING *`,
    [patientId, med.name, med.dosage, med.notes, med.start_date, med.end_date],
  );
  return rows[0];
}

export async function updatePatientMedication(
  client: PoolClient,
  patientId: string,
  medicationId: string,
  med: {
    name: string;
    dosage: string | null;
    notes: string | null;
    start_date: string | null;
    end_date: string | null;
  },
) {
  const { rows } = await client.query(
    `UPDATE medications
		SET name = $1,
		    dosage = $2,
		    notes = $3,
		    start_date = $4,
		    end_date = $5,
		    updated_at = NOW(),
		    server_updated_at = NOW()
		WHERE id = $6
		  AND user_id = $7
		  AND deleted_at IS NULL
		RETURNING *`,
    [
      med.name,
      med.dosage,
      med.notes,
      med.start_date,
      med.end_date,
      medicationId,
      patientId,
    ],
  );
  return rows[0] ?? null;
}

export async function softDeletePatientMedication(
  client: PoolClient,
  patientId: string,
  medicationId: string,
) {
  const { rows } = await client.query(
    `UPDATE medications
		SET deleted_at = NOW(),
		    updated_at = NOW(),
		    server_updated_at = NOW()
		WHERE id = $1
		  AND user_id = $2
		  AND deleted_at IS NULL
		RETURNING *`,
    [medicationId, patientId],
  );
  if (!rows[0]) return null;

  await client.query(
    `UPDATE schedules
		SET deleted_at = NOW(),
		    updated_at = NOW(),
		    server_updated_at = NOW()
		WHERE medication_id = $1
		  AND deleted_at IS NULL`,
    [medicationId],
  );

  await client.query(
    `UPDATE intakes
		SET deleted_at = NOW(),
		    updated_at = NOW(),
		    server_updated_at = NOW()
		WHERE medication_id = $1
		  AND deleted_at IS NULL`,
    [medicationId],
  );

  return rows[0];
}

export async function replacePatientMedicationSchedule(
  client: PoolClient,
  medicationId: string,
  schedule: {
    frequency_type: string;
    time_of_day: string | null;
    days_of_week: number[];
    interval_hours: number | null;
    interval_days: number | null;
  },
) {
  await client.query(
    `UPDATE schedules
		SET deleted_at = NOW(),
		    updated_at = NOW(),
		    server_updated_at = NOW()
		WHERE medication_id = $1
		  AND deleted_at IS NULL`,
    [medicationId],
  );

  const { rows } = await client.query(
    `INSERT INTO schedules (medication_id, frequency_type, time_of_day,
			days_of_week, interval_hours, interval_days, created_at, updated_at,
			server_updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW(), NOW())
		RETURNING *`,
    [
      medicationId,
      schedule.frequency_type,
      schedule.time_of_day,
      schedule.days_of_week,
      schedule.interval_hours,
      schedule.interval_days,
    ],
  );
  return rows[0];
}

export async function getPatientHistory(
  client: PoolClient,
  patientId: string,
  caregiverId: string,
  status?: string,
) {
  const params = [patientId, caregiverId] as string[];
  const statusFilter =
    status && status !== "all"
      ? `WHERE history.status = $${params.push(status)}`
      : "";

  const { rows } = await client.query(
    `WITH active_link AS (
        SELECT pc.notify_delay_min, u.timezone
        FROM patient_caregiver pc
        JOIN users u ON u.id = pc.patient_id
        WHERE pc.patient_id = $1
          AND pc.caregiver_id = $2
          AND pc.status = 'active'
        LIMIT 1
      ),
      actual_history AS (
        SELECT
          i.id::text AS id,
          i.medication_id::text AS medication_id,
          m.name AS medication_name,
          m.dosage AS medication_dosage,
          i.scheduled_time,
          i.taken_at,
          i.status,
          i.source,
          s.time_of_day AS scheduled_time_of_day
        FROM intakes i
        JOIN medications m ON i.medication_id = m.id
        LEFT JOIN schedules s
          ON s.medication_id = m.id
         AND s.deleted_at IS NULL
        WHERE i.user_id = $1
          AND i.deleted_at IS NULL
          AND m.deleted_at IS NULL
      ),
      expected_occurrences AS (
        SELECT
          CONCAT(
            'missed-',
            m.id::text,
            '-',
            TO_CHAR(occ.local_date::date, 'YYYYMMDD'),
            '-',
            REPLACE(s.time_of_day, ':', '')
          ) AS id,
          m.id::text AS medication_id,
          m.name AS medication_name,
          m.dosage AS medication_dosage,
          ((((occ.local_date::date)::text || ' ' || s.time_of_day)::timestamp)
            AT TIME ZONE al.timezone) AS scheduled_time,
          NULL::timestamptz AS taken_at,
          'missed'::text AS status,
          'auto'::text AS source,
          s.time_of_day AS scheduled_time_of_day
        FROM medications m
        JOIN schedules s
          ON s.medication_id = m.id
         AND s.deleted_at IS NULL
        JOIN active_link al ON TRUE
        CROSS JOIN LATERAL generate_series(
          (
            GREATEST(
              COALESCE(m.start_date, (NOW() AT TIME ZONE al.timezone)::date - 120),
              (NOW() AT TIME ZONE al.timezone)::date - 120
            )::timestamp
          ),
          (
            LEAST(
              COALESCE(m.end_date, (NOW() AT TIME ZONE al.timezone)::date),
              (NOW() AT TIME ZONE al.timezone)::date
            )::timestamp
          ),
          '1 day'::interval
        ) AS occ(local_date)
        WHERE m.user_id = $1
          AND m.deleted_at IS NULL
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
                (m.created_at AT TIME ZONE al.timezone)::date
              )
              AND MOD(
                occ.local_date::date - COALESCE(
                  m.start_date,
                  (m.created_at AT TIME ZONE al.timezone)::date
                ),
                GREATEST(COALESCE(s.interval_days, 1), 1)
              ) = 0
            )
          )
        UNION ALL
        SELECT
          CONCAT(
            'missed-',
            m.id::text,
            '-',
            TO_CHAR(occ.local_scheduled, 'YYYYMMDDHH24MI')
          ) AS id,
          m.id::text AS medication_id,
          m.name AS medication_name,
          m.dosage AS medication_dosage,
          (occ.local_scheduled AT TIME ZONE al.timezone) AS scheduled_time,
          NULL::timestamptz AS taken_at,
          'missed'::text AS status,
          'auto'::text AS source,
          TO_CHAR(occ.local_scheduled, 'HH24:MI') AS scheduled_time_of_day
        FROM medications m
        JOIN schedules s
          ON s.medication_id = m.id
         AND s.deleted_at IS NULL
        JOIN active_link al ON TRUE
        CROSS JOIN LATERAL generate_series(
          (((COALESCE(
              m.start_date,
              (m.created_at AT TIME ZONE al.timezone)::date
            )::text || ' ' || s.time_of_day)::timestamp)),
          LEAST(
            COALESCE(
              ((m.end_date::text || ' 23:59')::timestamp),
              (NOW() AT TIME ZONE al.timezone)
            ),
            (NOW() AT TIME ZONE al.timezone)
          ),
          (GREATEST(COALESCE(s.interval_hours, 1), 1)::text || ' hours')::interval
        ) AS occ(local_scheduled)
        WHERE m.user_id = $1
          AND m.deleted_at IS NULL
          AND m.archived_at IS NULL
          AND s.time_of_day IS NOT NULL
          AND s.frequency_type = 'interval'
      ),
      synthetic_missed AS (
        SELECT
          eo.id,
          eo.medication_id,
          eo.medication_name,
          eo.medication_dosage,
          eo.scheduled_time,
          eo.taken_at,
          eo.status,
          eo.source,
          eo.scheduled_time_of_day
        FROM expected_occurrences eo
        JOIN active_link al ON TRUE
        WHERE (eo.scheduled_time + (al.notify_delay_min || ' minutes')::interval) < NOW()
      ),
      filtered_synthetic_missed AS (
        SELECT
          sm.id,
          sm.medication_id,
          sm.medication_name,
          sm.medication_dosage,
          sm.scheduled_time,
          sm.taken_at,
          sm.status,
          sm.source,
          sm.scheduled_time_of_day
        FROM synthetic_missed sm
        WHERE NOT EXISTS (
            SELECT 1
            FROM intakes i
            WHERE i.medication_id::text = sm.medication_id
              AND i.user_id = $1
              AND i.deleted_at IS NULL
              AND i.scheduled_time = sm.scheduled_time
          )
      )
      SELECT *
      FROM (
        SELECT * FROM actual_history
        UNION ALL
        SELECT * FROM filtered_synthetic_missed
      ) AS history
      ${statusFilter}
      ORDER BY history.scheduled_time DESC
      LIMIT 120`,
    params,
  );
  return rows;
}

export async function getSelfPatientHistoryForReport(
  client: PoolClient,
  patientId: string,
) {
  const { rows } = await client.query(
    `WITH active_context AS (
        SELECT u.miss_delay_min AS notify_delay_min, u.timezone
        FROM users u
        WHERE u.id = $1
        LIMIT 1
      ),
      actual_history AS (
        SELECT
          i.id::text AS id,
          i.medication_id::text AS medication_id,
          m.name AS medication_name,
          m.dosage AS medication_dosage,
          i.scheduled_time,
          i.taken_at,
          i.status,
          i.source,
          s.time_of_day AS scheduled_time_of_day
        FROM intakes i
        JOIN medications m ON i.medication_id = m.id
        LEFT JOIN schedules s
          ON s.medication_id = m.id
         AND s.deleted_at IS NULL
        WHERE i.user_id = $1
          AND i.deleted_at IS NULL
          AND m.deleted_at IS NULL
      ),
      expected_occurrences AS (
        SELECT
          CONCAT(
            'missed-',
            m.id::text,
            '-',
            TO_CHAR(occ.local_date::date, 'YYYYMMDD'),
            '-',
            REPLACE(s.time_of_day, ':', '')
          ) AS id,
          m.id::text AS medication_id,
          m.name AS medication_name,
          m.dosage AS medication_dosage,
          ((((occ.local_date::date)::text || ' ' || s.time_of_day)::timestamp)
            AT TIME ZONE ac.timezone) AS scheduled_time,
          NULL::timestamptz AS taken_at,
          'missed'::text AS status,
          'auto'::text AS source,
          s.time_of_day AS scheduled_time_of_day
        FROM medications m
        JOIN schedules s
          ON s.medication_id = m.id
         AND s.deleted_at IS NULL
        JOIN active_context ac ON TRUE
        CROSS JOIN LATERAL generate_series(
          (
            GREATEST(
              COALESCE(m.start_date, (NOW() AT TIME ZONE ac.timezone)::date - 120),
              (NOW() AT TIME ZONE ac.timezone)::date - 120
            )::timestamp
          ),
          (
            LEAST(
              COALESCE(m.end_date, (NOW() AT TIME ZONE ac.timezone)::date),
              (NOW() AT TIME ZONE ac.timezone)::date
            )::timestamp
          ),
          '1 day'::interval
        ) AS occ(local_date)
        WHERE m.user_id = $1
          AND m.deleted_at IS NULL
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
                (m.created_at AT TIME ZONE ac.timezone)::date
              )
              AND MOD(
                occ.local_date::date - COALESCE(
                  m.start_date,
                  (m.created_at AT TIME ZONE ac.timezone)::date
                ),
                GREATEST(COALESCE(s.interval_days, 1), 1)
              ) = 0
            )
          )
        UNION ALL
        SELECT
          CONCAT(
            'missed-',
            m.id::text,
            '-',
            TO_CHAR(occ.local_scheduled, 'YYYYMMDDHH24MI')
          ) AS id,
          m.id::text AS medication_id,
          m.name AS medication_name,
          m.dosage AS medication_dosage,
          (occ.local_scheduled AT TIME ZONE ac.timezone) AS scheduled_time,
          NULL::timestamptz AS taken_at,
          'missed'::text AS status,
          'auto'::text AS source,
          TO_CHAR(occ.local_scheduled, 'HH24:MI') AS scheduled_time_of_day
        FROM medications m
        JOIN schedules s
          ON s.medication_id = m.id
         AND s.deleted_at IS NULL
        JOIN active_context ac ON TRUE
        CROSS JOIN LATERAL generate_series(
          (((COALESCE(
              m.start_date,
              (m.created_at AT TIME ZONE ac.timezone)::date
            )::text || ' ' || s.time_of_day)::timestamp)),
          LEAST(
            COALESCE(
              ((m.end_date::text || ' 23:59')::timestamp),
              (NOW() AT TIME ZONE ac.timezone)
            ),
            (NOW() AT TIME ZONE ac.timezone)
          ),
          (GREATEST(COALESCE(s.interval_hours, 1), 1)::text || ' hours')::interval
        ) AS occ(local_scheduled)
        WHERE m.user_id = $1
          AND m.deleted_at IS NULL
          AND m.archived_at IS NULL
          AND s.time_of_day IS NOT NULL
          AND s.frequency_type = 'interval'
      ),
      synthetic_missed AS (
        SELECT
          eo.id,
          eo.medication_id,
          eo.medication_name,
          eo.medication_dosage,
          eo.scheduled_time,
          eo.taken_at,
          eo.status,
          eo.source,
          eo.scheduled_time_of_day
        FROM expected_occurrences eo
        JOIN active_context ac ON TRUE
        WHERE (eo.scheduled_time + (ac.notify_delay_min || ' minutes')::interval) < NOW()
      ),
      filtered_synthetic_missed AS (
        SELECT
          sm.id,
          sm.medication_id,
          sm.medication_name,
          sm.medication_dosage,
          sm.scheduled_time,
          sm.taken_at,
          sm.status,
          sm.source,
          sm.scheduled_time_of_day
        FROM synthetic_missed sm
        WHERE NOT EXISTS (
          SELECT 1
          FROM intakes i
          WHERE i.medication_id::text = sm.medication_id
            AND i.user_id = $1
            AND i.deleted_at IS NULL
            AND i.scheduled_time = sm.scheduled_time
        )
      )
      SELECT *
      FROM (
        SELECT * FROM actual_history
        UNION ALL
        SELECT * FROM filtered_synthetic_missed
      ) AS history
      ORDER BY history.scheduled_time DESC
      LIMIT 120`,
    [patientId],
  );
  return rows;
}
