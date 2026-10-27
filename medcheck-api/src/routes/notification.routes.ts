import { Router } from "express";
import {
	handleRegisterDeviceToken,
	handleUnregisterDeviceTokens,
} from "@/controllers/notification.controller";
import { authMiddleware } from "@/middleware/auth";
import type { AuthenticatedRequest } from "@/types";

const router = Router();

router.post("/device-token", authMiddleware, (req, res) =>
	handleRegisterDeviceToken(req as AuthenticatedRequest, res),
);

router.delete("/device-token", authMiddleware, (req, res) =>
	handleUnregisterDeviceTokens(req as AuthenticatedRequest, res),
);

export default router;
