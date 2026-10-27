import { Router } from "express";
import { getMyReport, googleAuth, updateMe } from "@/controllers/auth.controller";
import { authMiddleware } from "@/middleware/auth";
import type { AuthenticatedRequest } from "@/types";

const router = Router();

router.post("/google", googleAuth);
router.get("/me/report", authMiddleware, (req, res) =>
	getMyReport(req as AuthenticatedRequest, res),
);
router.put("/me", authMiddleware, (req, res) =>
	updateMe(req as AuthenticatedRequest, res),
);

export default router;
