import type { PoolClient } from "pg";
import type {
  SyncPushIntake,
  SyncPushMedication,
  SyncPushSchedule,
} from "@/types";

export async function findMedicationById(
  client: PoolClient,
  id: string,
  userId: string,
) {
  const { rows } = await client.query(
    "SELECT * FROM medications WHERE id = $1 AND user_id = $2",
    [id, userId],
  );
  return rows[0] ?? null;
}

export async function updateMedication(
  client: PoolClient,
  med: SyncPushMedication,
) {
  await client.query(
    `UPDATE medications SET
			name = $1, dosage = $2, notes = $3, start_date = $4, end_date = $5,
			archived_at = $6, deleted_at = $7, updated_at = $8, server_updated_at = NOW()
		WHERE id = $9`,
    [
      med.name,
      med.dosage,
      med.notes,
      med.start_date,
      med.end_date,
      med.archived_at,
      med.deleted_at,
      med.updated_at,
      med.remote_id,
    ],
  );

  if (med.remote_id && med.deleted_at) {
    await softDeleteMedicationRelations(
      client,
      med.remote_id,
      med.deleted_at,
      med.updated_at,
    );
  }
}

export async function softDeleteMedicationRelations(
  client: PoolClient,
  medicationId: string,
  deletedAt: string,
  updatedAt: string,
) {
  await client.query(
    `UPDATE schedules
		 SET deleted_at = $2,
		     updated_at = $3,
		     server_updated_at = NOW()
		 WHERE medication_id = $1
		   AND deleted_at IS NULL`,
    [medicationId, deletedAt, updatedAt],
  );

  await client.query(
    `UPDATE intakes
		 SET deleted_at = $2,
		     updated_at = $3,
		     server_updated_at = NOW()
		 WHERE medication_id = $1
		   AND deleted_at IS NULL`,
    [medicationId, deletedAt, updatedAt],
  );
}

export async function insertMedication(
  client: PoolClient,
  userId: string,
  med: SyncPushMedication,
): Promise<string> {
  const { rows } = await client.query(
    `INSERT INTO medications (user_id, name, dosage, notes, start_date, end_date,
			archived_at, deleted_at, created_at, updated_at, server_updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW())
		RETURNING id`,
    [
      userId,
      med.name,
      med.dosage,
      med.notes,
      med.start_date,
      med.end_date,
      med.archived_at,
      med.deleted_at,
      med.created_at,
      med.updated_at,
    ],
  );
  return rows[0].id;
}

export async function findScheduleById(
  client: PoolClient,
  id: string,
  userId: string,
) {
  const { rows } = await client.query(
    `SELECT s.* FROM schedules s
		 JOIN medications m ON s.medication_id = m.id
		 WHERE s.id = $1 AND m.user_id = $2`,
    [id, userId],
  );
  return rows[0] ?? null;
}

export async function findLatestActiveScheduleByMedication(
  client: PoolClient,
  medicationId: string,
  userId: string,
) {
  const { rows } = await client.query(
    `SELECT s.* FROM schedules s
		 JOIN medications m ON s.medication_id = m.id
		 WHERE s.medication_id = $1
		   AND m.user_id = $2
		   AND s.deleted_at IS NULL
		 ORDER BY s.updated_at DESC, s.created_at DESC, s.id DESC
		 LIMIT 1`,
    [medicationId, userId],
  );
  return rows[0] ?? null;
}

export async function updateSchedule(
  client: PoolClient,
  sched: SyncPushSchedule,
  medicationId: string,
  scheduleId = sched.remote_id,
) {
  if (!scheduleId) {
    throw new Error("scheduleId requerido para updateSchedule");
  }

  await client.query(
    `UPDATE schedules SET
			medication_id = $1, frequency_type = $2, time_of_day = $3,
			days_of_week = $4, interval_hours = $5, interval_days = $6,
			deleted_at = $7, updated_at = $8, server_updated_at = NOW()
		WHERE id = $9`,
    [
      medicationId,
      sched.frequency_type,
      sched.time_of_day,
      sched.days_of_week,
      sched.interval_hours,
      sched.interval_days,
      sched.deleted_at,
      sched.updated_at,
      scheduleId,
    ],
  );
}

export async function insertSchedule(
  client: PoolClient,
  medicationId: string,
  sched: SyncPushSchedule,
): Promise<string> {
  const { rows } = await client.query(
    `INSERT INTO schedules (medication_id, frequency_type, time_of_day,
			days_of_week, interval_hours, interval_days, deleted_at,
			created_at, updated_at, server_updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
		RETURNING id`,
    [
      medicationId,
      sched.frequency_type,
      sched.time_of_day,
      sched.days_of_week,
      sched.interval_hours,
      sched.interval_days,
      sched.deleted_at,
      sched.created_at,
      sched.updated_at,
    ],
  );
  return rows[0].id;
}

export async function findIntakeById(
  client: PoolClient,
  id: string,
  userId: string,
) {
  const { rows } = await client.query(
    `SELECT i.* FROM intakes i
		 JOIN medications m ON i.medication_id = m.id
		 WHERE i.id = $1 AND m.user_id = $2`,
    [id, userId],
  );
  return rows[0] ?? null;
}

export async function findIntakeByDedup(
  client: PoolClient,
  medicationId: string,
  scheduledTime: string,
  userId: string,
) {
  const { rows } = await client.query(
    `SELECT * FROM intakes
		 WHERE medication_id = $1 AND scheduled_time = $2 AND user_id = $3`,
    [medicationId, scheduledTime, userId],
  );
  return rows[0] ?? null;
}

export async function updateIntakeDeletedAt(
  client: PoolClient,
  id: string,
  deletedAt: string,
  updatedAt: string,
) {
  await client.query(
    `UPDATE intakes SET deleted_at = $1, updated_at = $2, server_updated_at = NOW()
		 WHERE id = $3`,
    [deletedAt, updatedAt, id],
  );
}

export async function updateIntakeFull(
  client: PoolClient,
  id: string,
  medicationId: string,
  intake: SyncPushIntake,
  clearDeletedAt: boolean,
) {
  await client.query(
    `UPDATE intakes SET
			medication_id = $1, scheduled_time = $2, taken_at = $3,
			status = $4, source = $5, deleted_at = ${clearDeletedAt ? "NULL" : "$8"},
			updated_at = $6, server_updated_at = NOW()
		WHERE id = $7`,
    clearDeletedAt
      ? [
          medicationId,
          intake.scheduled_time,
          intake.status === "taken" ? intake.taken_at : null,
          intake.status,
          intake.source,
          intake.updated_at,
          id,
        ]
      : [
          medicationId,
          intake.scheduled_time,
          intake.status === "taken" ? intake.taken_at : null,
          intake.status,
          intake.source,
          intake.updated_at,
          id,
          intake.deleted_at,
        ],
  );
}

export async function updateIntakeStatus(
  client: PoolClient,
  id: string,
  intake: SyncPushIntake,
  clearDeletedAt: boolean,
) {
  if (clearDeletedAt) {
    await client.query(
      `UPDATE intakes SET taken_at = $1, status = $2, source = $3,
			 deleted_at = NULL, updated_at = $4, server_updated_at = NOW()
			WHERE id = $5`,
      [
        intake.status === "taken" ? intake.taken_at : null,
        intake.status,
        intake.source,
        intake.updated_at,
        id,
      ],
    );
  } else {
    await client.query(
      `UPDATE intakes SET taken_at = $1, status = $2, source = $3,
			 updated_at = $4, server_updated_at = NOW()
			WHERE id = $5`,
      [
        intake.status === "taken" ? intake.taken_at : null,
        intake.status,
        intake.source,
        intake.updated_at,
        id,
      ],
    );
  }
}

export async function insertIntake(
  client: PoolClient,
  userId: string,
  medicationId: string,
  intake: SyncPushIntake,
): Promise<string> {
  const { rows } = await client.query(
    `INSERT INTO intakes (medication_id, user_id, scheduled_time, taken_at,
			status, source, deleted_at, created_at, updated_at, server_updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
		RETURNING id`,
    [
      medicationId,
      userId,
      intake.scheduled_time,
      intake.status === "taken" ? intake.taken_at : null,
      intake.status,
      intake.source,
      intake.deleted_at,
      intake.created_at,
      intake.updated_at,
    ],
  );
  return rows[0].id;
}

export async function pullMedications(
  client: PoolClient,
  userId: string,
  since: string,
) {
  const { rows } = await client.query(
    "SELECT * FROM medications WHERE user_id = $1 AND server_updated_at > $2",
    [userId, since],
  );
  return rows;
}

export async function pullSchedules(
  client: PoolClient,
  userId: string,
  since: string,
) {
  const { rows } = await client.query(
    `SELECT s.* FROM schedules s
		 JOIN medications m ON s.medication_id = m.id
		 WHERE m.user_id = $1 AND s.server_updated_at > $2`,
    [userId, since],
  );
  return rows;
}

export async function pullIntakes(
  client: PoolClient,
  userId: string,
  since: string,
) {
  const { rows } = await client.query(
    "SELECT * FROM intakes WHERE user_id = $1 AND server_updated_at > $2",
    [userId, since],
  );
  return rows;
}
