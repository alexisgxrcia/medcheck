import type { Response } from "express";
import { syncPushSchema } from "@/schemas/sync.schema";
import { processSync } from "@/services/sync.service";
import type { AuthenticatedRequest } from "@/types";

export async function handleSync(req: AuthenticatedRequest, res: Response) {
  try {
    const result = syncPushSchema.safeParse(req.body);

    if (!result.success) {
      res.status(400).json({
        error: "Datos de sync inválidos",
        issues: result.error.issues,
      });
      return;
    }

    const syncResult = await processSync(req.userId!, result.data);
    res.json(syncResult);
  } catch (error: any) {
    console.error("Error en sync:", error);
    res.status(500).json({ error: "Error procesando sync" });
  }
}
