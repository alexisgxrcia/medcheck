import type { PoolClient } from "pg";
import dayjs from "dayjs";
import utc from "dayjs/plugin/utc";
import { withTransaction } from "@/config/database";
import { notifyUser } from "@/services/sse.service";
import { getActiveCaregiverIdsByPatientId } from "@/repositories/link.repository";
import * as repo from "@/repositories/sync.repository";
import type {
  IdMappings,
  SyncPushIntake,
  SyncPushMedication,
  SyncPushPayload,
  SyncPushSchedule,
  SyncResponse,
} from "@/types";

dayjs.extend(utc);

const STATUS_PRIORITY: Record<string, number> = {
  taken: 3,
  skipped: 2,
  missed: 1,
};

function toInstantMs(value: string): number {
  return dayjs(value).valueOf();
}

export async function processSync(
  userId: string,
  payload: SyncPushPayload,
): Promise<SyncResponse> {
  const hasCaregiverVisibleChanges = hasCaregiverVisibleChangesInPayload(payload);

  const syncResult = await withTransaction(async (client) => {
    const idMappings = await processPush(client, userId, payload.changes);
    const changes = await processPull(client, userId, payload.last_synced_at);

    return {
      changes,
      id_mappings: idMappings,
      server_time: dayjs.utc().toISOString(),
    };
  });

  if (hasCaregiverVisibleChanges) {
    await notifyActiveCaregiversOfPatientUpdate(userId);
  }

  return syncResult;
}

function hasCaregiverVisibleChangesInPayload(payload: SyncPushPayload): boolean {
  return (
    payload.changes.medications.length > 0 ||
    payload.changes.schedules.length > 0 ||
    payload.changes.intakes.length > 0
  );
}

async function notifyActiveCaregiversOfPatientUpdate(
  patientId: string,
): Promise<void> {
  const caregiverIds = await withTransaction((client) =>
    getActiveCaregiverIdsByPatientId(client, patientId),
  );

  for (const caregiverId of new Set(caregiverIds)) {
    notifyUser(caregiverId, "caregiver_data_changed");
  }
}

async function processPush(
  client: PoolClient,
  userId: string,
  changes: SyncPushPayload["changes"],
): Promise<IdMappings> {
  const idMappings: IdMappings = {
    medications: {},
    schedules: {},
    intakes: {},
  };

  for (const med of changes.medications) {
    const remoteId = await upsertMedication(client, userId, med);
    if (remoteId) {
      idMappings.medications[String(med.client_id)] = remoteId;
    }
  }

  for (const sched of changes.schedules) {
    const medicationId =
      idMappings.medications[String(sched.medication_client_id)] ||
      sched.medication_remote_id;
    if (!medicationId) continue;

    const remoteId = await upsertSchedule(client, userId, sched, medicationId);
    if (remoteId) {
      idMappings.schedules[String(sched.client_id)] = remoteId;
    }
  }

  for (const intake of changes.intakes) {
    const medicationId =
      idMappings.medications[String(intake.medication_client_id)] ||
      intake.medication_remote_id;
    if (!medicationId) continue;

    const remoteId = await upsertIntake(client, userId, intake, medicationId);
    if (remoteId) {
      idMappings.intakes[String(intake.client_id)] = remoteId;
    }
  }

  return idMappings;
}

async function upsertMedication(
  client: PoolClient,
  userId: string,
  med: SyncPushMedication,
): Promise<string | null> {
  if (med.remote_id) {
    const existing = await repo.findMedicationById(
      client,
      med.remote_id,
      userId,
    );

    if (existing) {
      if (existing.deleted_at && !med.deleted_at) return med.remote_id;
      if (toInstantMs(med.updated_at) <= toInstantMs(existing.updated_at))
        return med.remote_id;

      await repo.updateMedication(client, med);
      return med.remote_id;
    }
  }

  return repo.insertMedication(client, userId, med);
}

async function upsertSchedule(
  client: PoolClient,
  userId: string,
  sched: SyncPushSchedule,
  medicationId: string,
): Promise<string | null> {
  const medication = await repo.findMedicationById(client, medicationId, userId);
  if (!medication) {
    return null;
  }

  if (medication.deleted_at && !sched.deleted_at) {
    return null;
  }

  if (sched.remote_id) {
    const existing = await repo.findScheduleById(
      client,
      sched.remote_id,
      userId,
    );

    if (existing) {
      if (existing.deleted_at && !sched.deleted_at) return sched.remote_id;
      if (toInstantMs(sched.updated_at) <= toInstantMs(existing.updated_at))
        return sched.remote_id;

      await repo.updateSchedule(client, sched, medicationId);
      return sched.remote_id;
    }
  }

  const activeSchedule = await repo.findLatestActiveScheduleByMedication(
    client,
    medicationId,
    userId,
  );

  if (activeSchedule) {
    if (toInstantMs(sched.updated_at) <= toInstantMs(activeSchedule.updated_at)) {
      return activeSchedule.id;
    }

    await repo.updateSchedule(client, sched, medicationId, activeSchedule.id);
    return activeSchedule.id;
  }

  return repo.insertSchedule(client, medicationId, sched);
}

async function upsertIntake(
  client: PoolClient,
  userId: string,
  intake: SyncPushIntake,
  medicationId: string,
): Promise<string | null> {
  const medication = await repo.findMedicationById(client, medicationId, userId);
  if (!medication) {
    return null;
  }

  if (medication.deleted_at && !intake.deleted_at) {
    return null;
  }

  if (intake.remote_id) {
    const existing = await repo.findIntakeById(
      client,
      intake.remote_id,
      userId,
    );

    if (existing) {
      if (intake.deleted_at) {
        await repo.updateIntakeDeletedAt(
          client,
          intake.remote_id,
          intake.deleted_at,
          intake.updated_at,
        );
        return intake.remote_id;
      }

      if (existing.deleted_at && !intake.deleted_at) {
        await repo.updateIntakeFull(
          client,
          intake.remote_id,
          medicationId,
          intake,
          true,
        );
        return intake.remote_id;
      }

      const inPri = STATUS_PRIORITY[intake.status] ?? 0;
      const exPri = STATUS_PRIORITY[existing.status] ?? 0;

      if (
        inPri > exPri ||
        (inPri === exPri &&
          toInstantMs(intake.updated_at) > toInstantMs(existing.updated_at))
      ) {
        await repo.updateIntakeFull(
          client,
          intake.remote_id,
          medicationId,
          intake,
          false,
        );
      }
      return intake.remote_id;
    }
  }

  const existingDup = await repo.findIntakeByDedup(
    client,
    medicationId,
    intake.scheduled_time,
    userId,
  );

  if (existingDup) {
    if (intake.deleted_at) {
      await repo.updateIntakeDeletedAt(
        client,
        existingDup.id,
        intake.deleted_at,
        intake.updated_at,
      );
      return existingDup.id;
    }

    if (existingDup.deleted_at && !intake.deleted_at) {
      await repo.updateIntakeStatus(client, existingDup.id, intake, true);
      return existingDup.id;
    }

    const inPri = STATUS_PRIORITY[intake.status] ?? 0;
    const exPri = STATUS_PRIORITY[existingDup.status] ?? 0;

    if (
      inPri > exPri ||
      (inPri === exPri &&
        toInstantMs(intake.updated_at) > toInstantMs(existingDup.updated_at))
    ) {
      await repo.updateIntakeStatus(client, existingDup.id, intake, false);
    }
    return existingDup.id;
  }

  return repo.insertIntake(client, userId, medicationId, intake);
}

async function processPull(
  client: PoolClient,
  userId: string,
  since: string | null,
) {
  const sinceDate = since || "1970-01-01T00:00:00Z";

  const [medications, schedules, intakes] = await Promise.all([
    repo.pullMedications(client, userId, sinceDate),
    repo.pullSchedules(client, userId, sinceDate),
    repo.pullIntakes(client, userId, sinceDate),
  ]);

  return { medications, schedules, intakes };
}
