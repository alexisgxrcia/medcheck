import { Router } from "express";
import { handleSync } from "@/controllers/sync.controller";
import { authMiddleware } from "@/middleware/auth";
import type { AuthenticatedRequest } from "@/types";

const router = Router();

router.post("/", authMiddleware, (req, res) =>
	handleSync(req as AuthenticatedRequest, res),
);

export default router;
