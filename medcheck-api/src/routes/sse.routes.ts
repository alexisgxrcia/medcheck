import { Router } from "express";
import { authMiddleware } from "@/middleware/auth";
import { addClient, removeClient } from "@/services/sse.service";
import type { AuthenticatedRequest } from "@/types";

const router = Router();

router.get("/sync", authMiddleware, (req, res) => {
	const userId = (req as AuthenticatedRequest).userId!;

	res.setHeader("Content-Type", "text/event-stream");
	res.setHeader("Cache-Control", "no-cache");
	res.setHeader("Connection", "keep-alive");
	res.setHeader("X-Accel-Buffering", "no");
	res.flushHeaders();

	res.write(`data: ${JSON.stringify({ event: "connected" })}\n\n`);

	addClient(userId, res);

	const heartbeat = setInterval(() => {
		try {
			res.write(": heartbeat\n\n");
		} catch {
			clearInterval(heartbeat);
		}
	}, 15_000);

	req.on("close", () => {
		clearInterval(heartbeat);
		removeClient(userId, res);
	});
});

export default router;
