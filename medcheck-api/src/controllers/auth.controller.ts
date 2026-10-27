import type { Request, Response } from "express";
import { withTransaction } from "@/config/database";
import { getActiveCaregiverIdsByPatientId } from "@/repositories/link.repository";
import { notifyUser } from "@/services/sse.service";
import {
  generateJwt,
  updateProfile,
  upsertUser,
  verifyGoogleToken,
} from "@/services/auth.service";
import { getOwnPatientReportService } from "@/services/link.service";
import type { AuthenticatedRequest } from "@/types";

async function notifyCaregiversOfProfileChange(patientId: string) {
  const caregiverIds = await withTransaction((client) =>
    getActiveCaregiverIdsByPatientId(client, patientId),
  );

  for (const caregiverId of new Set(caregiverIds)) {
    notifyUser(caregiverId, "patient_profile_changed");
  }
}

export async function googleAuth(req: Request, res: Response) {
  try {
    const { id_token, email, provider_id, display_name, timezone } = req.body;

    let googleUser: { sub: string; email: string; name?: string };

    if (id_token) {
      googleUser = await verifyGoogleToken(id_token);
    } else if (email && provider_id) {
      googleUser = { sub: provider_id, email, name: display_name };
    } else {
      res
        .status(400)
        .json({ error: "Se requiere id_token o (email + provider_id)" });
      return;
    }

    const authResult = await upsertUser(
      googleUser.email,
      googleUser.sub,
      googleUser.name,
      typeof timezone === "string" && timezone.trim().length > 0
        ? timezone
        : "America/Mazatlan",
    );
    const { user, isNewUser } = authResult;
    const token = generateJwt(user.id, user.email);

    res.json({ token, user, is_new_user: isNewUser });
  } catch (error: any) {
    console.error("Error en auth/google:", error.message);
    res.status(401).json({ error: error.message || "Autenticación fallida" });
  }
}

export async function updateMe(req: AuthenticatedRequest, res: Response) {
  try {
    const {
      role,
      display_name,
      birth_date,
      weight_kg,
      height_cm,
      timezone,
      notifications_enabled,
      dark_mode,
    } = req.body;

    if (role !== undefined && role !== "patient" && role !== "caregiver") {
      res.status(400).json({ error: "role debe ser 'patient' o 'caregiver'" });
      return;
    }

    const user = await updateProfile(req.userId!, {
      role,
      display_name,
      birth_date,
      weight_kg,
      height_cm,
      timezone,
      notifications_enabled,
      dark_mode,
    });

    if (!user) {
      res.status(404).json({ error: "Usuario no encontrado" });
      return;
    }

    res.json({ user });
    await notifyCaregiversOfProfileChange(req.userId!);
  } catch (error: any) {
    console.error("Error actualizando usuario:", error.message);
    res.status(500).json({ error: "Error actualizando usuario" });
  }
}

export async function getMyReport(req: AuthenticatedRequest, res: Response) {
  try {
    const result = await getOwnPatientReportService(req.userId!);

    if (!result.success) {
      res.status(result.status ?? 400).json({ error: result.error });
      return;
    }

    const filename = `informe-mi-salud-${new Date().toISOString().split("T")[0]}.pdf`;
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
    res.send(result.pdf);
  } catch (error) {
    console.error("Error generando informe propio PDF:", error);
    res.status(500).json({ error: "Error generando informe" });
  }
}
