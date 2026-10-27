import { Router } from "express";
import {
	handleAcceptLink,
	handleCreatePatientMedication,
	handleDeletePatientMedication,
	handleGetLinks,
	handleGetPending,
	handleGetPatientHistory,
	handleGetPatientMedications,
	handleGetPatientProfile,
	handleGetPatientReport,
	handleLink,
	handleRejectLink,
	handleRevokeLink,
	handleUpdatePatientMedication,
	handleUpdateLinkSettings,
} from "@/controllers/link.controller";
import { authMiddleware } from "@/middleware/auth";
import type { AuthenticatedRequest } from "@/types";

const router = Router();

router.post("/", authMiddleware, (req, res) =>
	handleLink(req as AuthenticatedRequest, res),
);

router.get("/", authMiddleware, (req, res) =>
	handleGetLinks(req as AuthenticatedRequest, res),
);

router.get("/pending", authMiddleware, (req, res) =>
	handleGetPending(req as AuthenticatedRequest, res),
);

router.get("/:id/medications", authMiddleware, (req, res) =>
	handleGetPatientMedications(req as AuthenticatedRequest, res),
);

router.get("/:id/profile", authMiddleware, (req, res) =>
	handleGetPatientProfile(req as AuthenticatedRequest, res),
);

router.post("/:id/medications", authMiddleware, (req, res) =>
	handleCreatePatientMedication(req as AuthenticatedRequest, res),
);

router.put("/:id/medications/:medicationId", authMiddleware, (req, res) =>
	handleUpdatePatientMedication(req as AuthenticatedRequest, res),
);

router.delete("/:id/medications/:medicationId", authMiddleware, (req, res) =>
	handleDeletePatientMedication(req as AuthenticatedRequest, res),
);

router.get("/:id/history", authMiddleware, (req, res) =>
	handleGetPatientHistory(req as AuthenticatedRequest, res),
);

router.get("/:id/report", authMiddleware, (req, res) =>
	handleGetPatientReport(req as AuthenticatedRequest, res),
);

router.put("/:id/accept", authMiddleware, (req, res) =>
	handleAcceptLink(req as AuthenticatedRequest, res),
);

router.put("/:id/reject", authMiddleware, (req, res) =>
	handleRejectLink(req as AuthenticatedRequest, res),
);

router.put("/:id/revoke", authMiddleware, (req, res) =>
	handleRevokeLink(req as AuthenticatedRequest, res),
);

router.put("/:id/settings", authMiddleware, (req, res) =>
	handleUpdateLinkSettings(req as AuthenticatedRequest, res),
);

export default router;
