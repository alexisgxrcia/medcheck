import type { PoolClient } from "pg";
import dayjs from "dayjs";
import utc from "dayjs/plugin/utc";
import { withTransaction } from "@/config/database";
import {
  acceptLink,
  findExistingLink,
  findActiveCaregiverLink,
  findUserByEmail,
  findUserById,
  getPatientHistory,
  getPatientProfile,
  getLinksForUser,
  getPatientMedicationById,
  getPatientMedications,
  getSelfPatientHistoryForReport,
  insertPatientMedication,
  insertLink,
  rejectLink,
  replacePatientMedicationSchedule,
  revokeLink,
  softDeletePatientMedication,
  updatePatientMedication,
  updateLinkSettings,
} from "@/repositories/link.repository";
import { sendEmail, buildAppInvitationEmail } from "@/services/email.service";
import { buildPatientReportPDF } from "@/services/pdf.service";

dayjs.extend(utc);

interface LinkResult {
  success: boolean;
  error?: string;
  status?: number;
  link?: Record<string, unknown>;
  target_user?: { id: string; email: string; display_name: string | null };
}

interface PatientProfileResult {
  id: string;
  email: string;
  display_name: string | null;
  birth_date: string | null;
  weight_kg: number | null;
  height_cm: number | null;
}

export async function createLink(
  userId: string,
  targetEmail: string,
  targetRole: "patient" | "caregiver",
  notifyOnMiss: boolean,
  notifyDelayMin: number,
): Promise<LinkResult> {
  const targetUser = await findUserByEmail(targetEmail);
  if (!targetUser) {
    const inviter = await findUserById(userId);
    const { subject, html } = buildAppInvitationEmail(
      inviter?.display_name ?? null,
      targetEmail,
      targetRole,
    );
    await sendEmail({ to: targetEmail, subject, html });

    return {
      success: false,
      error: `Usuario no encontrado. Se envió una invitación a ${targetEmail} para descargar la app.`,
      status: 404,
    };
  }

  if (targetUser.id === userId) {
    return {
      success: false,
      error: "No puedes vincularte contigo mismo.",
      status: 400,
    };
  }

  const patientId = targetRole === "patient" ? targetUser.id : userId;
  const caregiverId = targetRole === "caregiver" ? targetUser.id : userId;

  return withTransaction(async (client) => {
    const existing = await findExistingLink(client, patientId, caregiverId);
    if (existing) {
      return {
        success: false,
        error: "Ya existe un vínculo activo o pendiente.",
        status: 409,
      };
    }

    const link = await insertLink(
      client,
      patientId,
      caregiverId,
      notifyOnMiss,
      notifyDelayMin,
      userId,
    );

    return {
      success: true,
      link,
      target_user: {
        id: targetUser.id,
        email: targetUser.email,
        display_name: targetUser.display_name,
      },
    };
  });
}

export async function acceptLinkService(
  userId: string,
  linkId: string,
  notifyOnMiss?: boolean,
  notifyDelayMin?: number,
): Promise<LinkResult> {
  return withTransaction(async (client) => {
    const updated = await acceptLink(
      client,
      linkId,
      userId,
      notifyOnMiss,
      notifyDelayMin,
    );
    if (!updated) {
      return {
        success: false,
        error: "Solicitud no encontrada o ya procesada.",
        status: 404,
      };
    }
    return { success: true, link: updated };
  });
}

export async function getLinksService(userId: string) {
  return getLinksForUser(userId);
}

export async function revokeLinkService(
  userId: string,
  linkId: string,
): Promise<LinkResult> {
  return withTransaction(async (client) => {
    const updated = await revokeLink(client, linkId, userId);
    if (!updated) {
      return {
        success: false,
        error: "Vínculo no encontrado o no puedes cancelarlo.",
        status: 404,
      };
    }
    return { success: true, link: updated };
  });
}

export async function updateLinkSettingsService(
  userId: string,
  linkId: string,
  notifyOnMiss: boolean,
  notifyDelayMin: number,
): Promise<LinkResult> {
  return withTransaction(async (client) => {
    const updated = await updateLinkSettings(
      client,
      linkId,
      userId,
      notifyOnMiss,
      notifyDelayMin,
    );
    if (!updated) {
      return {
        success: false,
        error: "Vínculo activo no encontrado.",
        status: 404,
      };
    }
    return { success: true, link: updated };
  });
}

export async function rejectLinkService(
  userId: string,
  linkId: string,
): Promise<LinkResult> {
  return withTransaction(async (client) => {
    const updated = await rejectLink(client, linkId, userId);
    if (!updated) {
      return {
        success: false,
        error: "Solicitud no encontrada o ya procesada.",
        status: 404,
      };
    }
    return { success: true, link: updated };
  });
}

interface PatientMedicationPayload {
  medication: {
    name: string;
    dosage?: string | null;
    notes?: string | null;
    start_date?: string | null;
    end_date?: string | null;
  };
  schedule: {
    frequency_type: string;
    time_of_day?: string | null;
    days_of_week?: number[];
    interval_hours?: number | null;
    interval_days?: number | null;
  };
}

async function getActiveCaregiverLinkOrNull(
  client: PoolClient,
  userId: string,
  linkId: string,
) {
  return findActiveCaregiverLink(client, linkId, userId);
}

function normalizeMedicationPayload(payload: PatientMedicationPayload) {
  return {
    medication: {
      name: payload.medication.name.trim(),
      dosage: payload.medication.dosage?.trim() || null,
      notes: payload.medication.notes?.trim() || null,
      start_date: payload.medication.start_date ?? null,
      end_date: payload.medication.end_date ?? null,
    },
    schedule: {
      frequency_type: payload.schedule.frequency_type,
      time_of_day: payload.schedule.time_of_day ?? null,
      days_of_week: payload.schedule.days_of_week ?? [],
      interval_hours: payload.schedule.interval_hours ?? null,
      interval_days: payload.schedule.interval_days ?? null,
    },
  };
}

export async function getPatientMedicationsService(
  userId: string,
  linkId: string,
): Promise<LinkResult & { medications?: Record<string, unknown>[] }> {
  return withTransaction(async (client) => {
    const link = await getActiveCaregiverLinkOrNull(client, userId, linkId);
    if (!link) {
      return {
        success: false,
        error: "Vínculo activo no encontrado.",
        status: 404,
      };
    }

    const medications = await getPatientMedications(client, link.patient_id);
    return { success: true, medications };
  });
}

export async function getPatientProfileService(
  userId: string,
  linkId: string,
): Promise<LinkResult & { patient?: PatientProfileResult }> {
  return withTransaction(async (client) => {
    const link = await getActiveCaregiverLinkOrNull(client, userId, linkId);
    if (!link) {
      return {
        success: false,
        error: "Vínculo activo no encontrado.",
        status: 404,
      };
    }

    const patient = await getPatientProfile(client, link.patient_id);
    if (!patient) {
      return {
        success: false,
        error: "Paciente no encontrado.",
        status: 404,
      };
    }

    return { success: true, patient };
  });
}

export async function createPatientMedicationService(
  userId: string,
  linkId: string,
  payload: PatientMedicationPayload,
): Promise<LinkResult & { medication?: Record<string, unknown>; patient_id?: string }> {
  return withTransaction(async (client) => {
    const link = await getActiveCaregiverLinkOrNull(client, userId, linkId);
    if (!link) {
      return {
        success: false,
        error: "Vínculo activo no encontrado.",
        status: 404,
      };
    }

    const data = normalizeMedicationPayload(payload);
    if (!data.medication.name) {
      return { success: false, error: "Nombre requerido.", status: 400 };
    }

    const medication = await insertPatientMedication(
      client,
      link.patient_id,
      data.medication,
    );
    await replacePatientMedicationSchedule(client, medication.id, data.schedule);
    const full = await getPatientMedicationById(
      client,
      link.patient_id,
      medication.id,
    );

    return { success: true, medication: full, patient_id: link.patient_id };
  });
}

export async function updatePatientMedicationService(
  userId: string,
  linkId: string,
  medicationId: string,
  payload: PatientMedicationPayload,
): Promise<LinkResult & { medication?: Record<string, unknown>; patient_id?: string }> {
  return withTransaction(async (client) => {
    const link = await getActiveCaregiverLinkOrNull(client, userId, linkId);
    if (!link) {
      return {
        success: false,
        error: "Vínculo activo no encontrado.",
        status: 404,
      };
    }

    const data = normalizeMedicationPayload(payload);
    if (!data.medication.name) {
      return { success: false, error: "Nombre requerido.", status: 400 };
    }

    const medication = await updatePatientMedication(
      client,
      link.patient_id,
      medicationId,
      data.medication,
    );
    if (!medication) {
      return {
        success: false,
        error: "Medicamento no encontrado.",
        status: 404,
      };
    }

    await replacePatientMedicationSchedule(client, medicationId, data.schedule);
    const full = await getPatientMedicationById(
      client,
      link.patient_id,
      medicationId,
    );

    return { success: true, medication: full, patient_id: link.patient_id };
  });
}

export async function deletePatientMedicationService(
  userId: string,
  linkId: string,
  medicationId: string,
): Promise<LinkResult & { patient_id?: string }> {
  return withTransaction(async (client) => {
    const link = await getActiveCaregiverLinkOrNull(client, userId, linkId);
    if (!link) {
      return {
        success: false,
        error: "Vínculo activo no encontrado.",
        status: 404,
      };
    }

    const medication = await softDeletePatientMedication(
      client,
      link.patient_id,
      medicationId,
    );
    if (!medication) {
      return {
        success: false,
        error: "Medicamento no encontrado.",
        status: 404,
      };
    }

    return { success: true, patient_id: link.patient_id };
  });
}

export async function getPatientHistoryService(
  userId: string,
  linkId: string,
  status?: string,
): Promise<LinkResult & { history?: Record<string, unknown>[] }> {
  return withTransaction(async (client) => {
    const link = await getActiveCaregiverLinkOrNull(client, userId, linkId);
    if (!link) {
      return {
        success: false,
        error: "Vínculo activo no encontrado.",
        status: 404,
      };
    }

    const history = await getPatientHistory(
      client,
      link.patient_id,
      link.caregiver_id,
      status,
    );
    return { success: true, history };
  });
}

export async function getPatientReportService(
  userId: string,
  linkId: string,
): Promise<LinkResult & { pdf?: Buffer }> {
  return withTransaction(async (client) => {
    const link = await getActiveCaregiverLinkOrNull(client, userId, linkId);
    if (!link) {
      return {
        success: false,
        error: "Vínculo activo no encontrado.",
        status: 404,
      };
    }

    const patient = await findUserById(link.patient_id);
    const caregiver = await findUserById(userId);
    const patientProfile = await getPatientProfile(client, link.patient_id);
    const medications = await getPatientMedications(client, link.patient_id);
    const history = await getPatientHistory(
      client,
      link.patient_id,
      link.caregiver_id,
    );

    const pdf = await buildPatientReportPDF({
      patientName: patient?.display_name || "Paciente",
      caregiverName: caregiver?.display_name || "Cuidador",
      patientEmail: patientProfile?.email ?? null,
      patientBirthDate: patientProfile?.birth_date ?? null,
      patientWeightKg: patientProfile?.weight_kg ?? null,
      patientHeightCm: patientProfile?.height_cm ?? null,
      patientTimezone: patientProfile?.timezone ?? "America/Mazatlan",
      generatedAt: dayjs.utc().toISOString(),
      medications: medications.map((m: any) => ({
        name: m.name,
        dosage: m.dosage,
        notes: m.notes,
        start_date: m.start_date,
        end_date: m.end_date,
        frequency_type: m.schedules?.[0]?.frequency_type,
        time_of_day: m.schedules?.[0]?.time_of_day,
        days_of_week: m.schedules?.[0]?.days_of_week ?? [],
        interval_hours: m.schedules?.[0]?.interval_hours ?? null,
        interval_days: m.schedules?.[0]?.interval_days ?? null,
      })),
      history: history.map((h: any) => ({
        scheduled_time: h.scheduled_time,
        scheduled_time_of_day: h.scheduled_time_of_day,
        taken_at: h.taken_at,
        status: h.status,
        medication_name: h.medication_name,
        medication_dosage: h.medication_dosage,
      })),
    });

    return { success: true, pdf };
  });
}

export async function getOwnPatientReportService(
  userId: string,
): Promise<LinkResult & { pdf?: Buffer }> {
  return withTransaction(async (client) => {
    const patient = await findUserById(userId);
    if (!patient) {
      return {
        success: false,
        error: "Usuario no encontrado.",
        status: 404,
      };
    }

    const patientProfile = await getPatientProfile(client, userId);
    const medications = await getPatientMedications(client, userId);
    const history = await getSelfPatientHistoryForReport(client, userId);

    const pdf = await buildPatientReportPDF({
      patientName: patient.display_name || "Paciente",
      caregiverName: patient.display_name || "Paciente",
      patientEmail: patientProfile?.email ?? null,
      patientBirthDate: patientProfile?.birth_date ?? null,
      patientWeightKg: patientProfile?.weight_kg ?? null,
      patientHeightCm: patientProfile?.height_cm ?? null,
      patientTimezone: patientProfile?.timezone ?? "America/Mazatlan",
      generatedAt: dayjs.utc().toISOString(),
      medications: medications.map((m: any) => ({
        name: m.name,
        dosage: m.dosage,
        notes: m.notes,
        start_date: m.start_date,
        end_date: m.end_date,
        frequency_type: m.schedules?.[0]?.frequency_type,
        time_of_day: m.schedules?.[0]?.time_of_day,
        days_of_week: m.schedules?.[0]?.days_of_week ?? [],
        interval_hours: m.schedules?.[0]?.interval_hours ?? null,
        interval_days: m.schedules?.[0]?.interval_days ?? null,
      })),
      history: history.map((h: any) => ({
        scheduled_time: h.scheduled_time,
        scheduled_time_of_day: h.scheduled_time_of_day,
        taken_at: h.taken_at,
        status: h.status,
        medication_name: h.medication_name,
        medication_dosage: h.medication_dosage,
      })),
    });

    return { success: true, pdf };
  });
}
