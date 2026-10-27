import dayjs from "dayjs";
import type { Response } from "express";
import { getPendingLinksForUser } from "@/repositories/link.repository";
import {
  acceptLinkService,
  createLink,
  createPatientMedicationService,
  deletePatientMedicationService,
  getLinksService,
  getPatientHistoryService,
  getPatientMedicationsService,
  getPatientProfileService,
  getPatientReportService,
  rejectLinkService,
  revokeLinkService,
  updateLinkSettingsService,
  updatePatientMedicationService,
} from "@/services/link.service";
import { notifyUser } from "@/services/sse.service";
import type { AuthenticatedRequest } from "@/types";

function notifyLinkParticipants(link: unknown) {
  if (!link || typeof link !== "object") return;

  const { patient_id, caregiver_id } = link as {
    patient_id?: string;
    caregiver_id?: string;
  };

  const recipients = [patient_id, caregiver_id].filter(
    (userId): userId is string => Boolean(userId),
  );

  for (const userId of new Set(recipients)) {
    notifyUser(userId, "links_updated");
  }
}

export async function handleLink(req: AuthenticatedRequest, res: Response) {
  try {
    const { email, role, notify_on_miss, notify_delay_min } = req.body;

    if (!email || !role) {
      res.status(400).json({ error: "Se requiere email y role" });
      return;
    }

    if (role !== "patient" && role !== "caregiver") {
      res.status(400).json({ error: "role debe ser 'patient' o 'caregiver'" });
      return;
    }

    const result = await createLink(
      req.userId!,
      email,
      role,
      notify_on_miss ?? true,
      notify_delay_min ?? 30,
    );

    if (!result.success) {
      res.status(result.status ?? 400).json({ error: result.error });
      return;
    }

    res.json({ link: result.link, target_user: result.target_user });

    notifyLinkParticipants({
      patient_id: (result.link as { patient_id?: string } | undefined)
        ?.patient_id,
      caregiver_id: (result.link as { caregiver_id?: string } | undefined)
        ?.caregiver_id,
    });
  } catch (error) {
    console.error("Error en link:", error);
    res.status(500).json({ error: "Error creando vínculo" });
  }
}

export async function handleAcceptLink(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const { id } = req.params;
    const { notify_on_miss, notify_delay_min } = req.body ?? {};

    const result = await acceptLinkService(
      req.userId!,
      id as string,
      notify_on_miss,
      notify_delay_min,
    );

    if (!result.success) {
      res.status(result.status ?? 400).json({ error: result.error });
      return;
    }

    res.json({ link: result.link });
    notifyLinkParticipants(result.link);
  } catch (error) {
    console.error("Error aceptando vínculo:", error);
    res.status(500).json({ error: "Error aceptando vínculo" });
  }
}

export async function handleRejectLink(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const { id } = req.params;

    const result = await rejectLinkService(req.userId!, id as string);

    if (!result.success) {
      res.status(result.status ?? 400).json({ error: result.error });
      return;
    }

    res.json({ link: result.link });
    notifyLinkParticipants(result.link);
  } catch (error) {
    console.error("Error rechazando vínculo:", error);
    res.status(500).json({ error: "Error rechazando vínculo" });
  }
}

export async function handleGetLinks(req: AuthenticatedRequest, res: Response) {
  try {
    const links = await getLinksService(req.userId!);
    res.json({ links });
  } catch (error) {
    console.error("Error obteniendo vínculos:", error);
    res.status(500).json({ error: "Error obteniendo vínculos" });
  }
}

export async function handleRevokeLink(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const { id } = req.params;

    const result = await revokeLinkService(req.userId!, id as string);

    if (!result.success) {
      res.status(result.status ?? 400).json({ error: result.error });
      return;
    }

    res.json({ link: result.link });
    notifyLinkParticipants(result.link);
  } catch (error) {
    console.error("Error revocando vínculo:", error);
    res.status(500).json({ error: "Error revocando vínculo" });
  }
}

export async function handleUpdateLinkSettings(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const { id } = req.params;
    const { notify_on_miss, notify_delay_min } = req.body;

    if (typeof notify_on_miss !== "boolean") {
      res.status(400).json({ error: "notify_on_miss debe ser boolean" });
      return;
    }

    if (typeof notify_delay_min !== "number") {
      res.status(400).json({ error: "notify_delay_min debe ser number" });
      return;
    }

    const result = await updateLinkSettingsService(
      req.userId!,
      id as string,
      notify_on_miss,
      notify_delay_min,
    );

    if (!result.success) {
      res.status(result.status ?? 400).json({ error: result.error });
      return;
    }

    res.json({ link: result.link });
  } catch (error) {
    console.error("Error actualizando vínculo:", error);
    res.status(500).json({ error: "Error actualizando vínculo" });
  }
}

export async function handleGetPending(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const role = req.query.role as string | undefined;
    const links = await getPendingLinksForUser(req.userId!, role);
    res.json({ pending: links });
  } catch (error) {
    console.error("Error obteniendo solicitudes:", error);
    res.status(500).json({ error: "Error obteniendo solicitudes" });
  }
}

export async function handleGetPatientMedications(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const { id } = req.params;
    const result = await getPatientMedicationsService(
      req.userId!,
      id as string,
    );

    if (!result.success) {
      res.status(result.status ?? 400).json({ error: result.error });
      return;
    }

    res.json({ medications: result.medications });
  } catch (error) {
    console.error("Error obteniendo medicamentos del paciente:", error);
    res.status(500).json({ error: "Error obteniendo medicamentos" });
  }
}

export async function handleGetPatientProfile(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const { id } = req.params;
    const result = await getPatientProfileService(req.userId!, id as string);

    if (!result.success) {
      res.status(result.status ?? 400).json({ error: result.error });
      return;
    }

    res.json({ patient: result.patient });
  } catch (error) {
    console.error("Error obteniendo perfil del paciente:", error);
    res.status(500).json({ error: "Error obteniendo perfil del paciente" });
  }
}

export async function handleCreatePatientMedication(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const { id } = req.params;
    const result = await createPatientMedicationService(
      req.userId!,
      id as string,
      req.body,
    );

    if (!result.success) {
      res.status(result.status ?? 400).json({ error: result.error });
      return;
    }

    res.json({ medication: result.medication });

    if (result.patient_id) {
      notifyUser(result.patient_id, "sync_needed");
    }
  } catch (error) {
    console.error("Error creando medicamento del paciente:", error);
    res.status(500).json({ error: "Error creando medicamento" });
  }
}

export async function handleUpdatePatientMedication(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const { id, medicationId } = req.params;
    const result = await updatePatientMedicationService(
      req.userId!,
      id as string,
      medicationId as string,
      req.body,
    );

    if (!result.success) {
      res.status(result.status ?? 400).json({ error: result.error });
      return;
    }

    res.json({ medication: result.medication });

    if (result.patient_id) {
      notifyUser(result.patient_id, "sync_needed");
    }
  } catch (error) {
    console.error("Error actualizando medicamento del paciente:", error);
    res.status(500).json({ error: "Error actualizando medicamento" });
  }
}

export async function handleDeletePatientMedication(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const { id, medicationId } = req.params;
    const result = await deletePatientMedicationService(
      req.userId!,
      id as string,
      medicationId as string,
    );

    if (!result.success) {
      res.status(result.status ?? 400).json({ error: result.error });
      return;
    }

    res.json({ ok: true });

    if (result.patient_id) {
      notifyUser(result.patient_id, "sync_needed");
    }
  } catch (error) {
    console.error("Error eliminando medicamento del paciente:", error);
    res.status(500).json({ error: "Error eliminando medicamento" });
  }
}

export async function handleGetPatientHistory(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const { id } = req.params;
    const status = req.query.status as string | undefined;
    const result = await getPatientHistoryService(
      req.userId!,
      id as string,
      status,
    );

    if (!result.success) {
      res.status(result.status ?? 400).json({ error: result.error });
      return;
    }

    res.json({ history: result.history });
  } catch (error) {
    console.error("Error obteniendo historial del paciente:", error);
    res.status(500).json({ error: "Error obteniendo historial" });
  }
}

export async function handleGetPatientReport(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const { id } = req.params;
    const result = await getPatientReportService(req.userId!, id as string);

    if (!result.success) {
      res.status(result.status ?? 400).json({ error: result.error });
      return;
    }

    const patientName = req.query.patient_name || "paciente";
    const filename = `informe-${patientName}-${dayjs().format("YYYY-MM-DD")}.pdf`;

    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
    res.send(result.pdf);
  } catch (error) {
    console.error("Error generando informe PDF:", error);
    res.status(500).json({ error: "Error generando informe" });
  }
}
