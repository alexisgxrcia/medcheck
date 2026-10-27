import type { Response } from "express";
import {
  registerDeviceToken,
  unregisterDeviceTokens,
} from "@/services/notification.service";
import type { AuthenticatedRequest } from "@/types";

export async function handleRegisterDeviceToken(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    const { token, platform } = req.body;

    if (!token || typeof token !== "string") {
      res.status(400).json({ error: "Token requerido" });
      return;
    }

    if (!platform || !["ios", "android"].includes(platform)) {
      res
        .status(400)
        .json({ error: "platform debe ser 'ios' o 'android'" });
      return;
    }

    const deviceToken = await registerDeviceToken(
      req.userId!,
      token,
      platform,
    );

    res.json({ success: true, device_token: deviceToken });
  } catch (error: any) {
    console.error("Error registrando device token:", error.message);
    res.status(500).json({ error: "Error registrando device token" });
  }
}

export async function handleUnregisterDeviceTokens(
  req: AuthenticatedRequest,
  res: Response,
) {
  try {
    await unregisterDeviceTokens(req.userId!);
    res.json({ success: true });
  } catch (error: any) {
    console.error("Error eliminando device tokens:", error.message);
    res.status(500).json({ error: "Error eliminando device tokens" });
  }
}
