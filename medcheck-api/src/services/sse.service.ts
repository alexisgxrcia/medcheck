import type { Response } from "express";
import {
  hasRedisUserEvents,
  publishUserEvent,
} from "@/services/redis.service";

const clients = new Map<string, Response[]>();

export function addClient(userId: string, res: Response): void {
	const existing = clients.get(userId) ?? [];
	existing.push(res);
	clients.set(userId, existing);

	console.log(
		`[SSE] Client connected: ${userId} (total: ${existing.length})`,
	);
}

export function removeClient(userId: string, res: Response): void {
	const existing = clients.get(userId);
	if (!existing) return;

	const filtered = existing.filter((r) => r !== res);
	if (filtered.length === 0) {
		clients.delete(userId);
	} else {
		clients.set(userId, filtered);
	}

	console.log(
		`[SSE] Client disconnected: ${userId} (remaining: ${filtered.length})`,
	);
}

export function notifyUser(userId: string, event: string): void {
	void dispatchUserEvent(userId, event);
}

export function deliverToLocalClients(userId: string, event: string): void {
	const userClients = clients.get(userId);
	if (!userClients || userClients.length === 0) {
		console.log(`[SSE] No active clients for user ${userId}, skipping`);
		return;
	}

	const payload = `data: ${JSON.stringify({ event })}\n\n`;

	for (const res of userClients) {
		try {
			res.write(payload);
		} catch (err) {
			console.error(`[SSE] Error writing to client ${userId}:`, err);
		}
	}

	console.log(
		`[SSE] Notified ${userClients.length} client(s) for user ${userId}: ${event}`,
	);
}

async function dispatchUserEvent(userId: string, event: string): Promise<void> {
	if (hasRedisUserEvents()) {
		try {
			await publishUserEvent(userId, event);
			return;
		} catch (err) {
			console.error(
				`[SSE] Redis publish failed for user ${userId}, falling back to local delivery:`,
				err,
			);
		}
	}

	deliverToLocalClients(userId, event);
}

export function getActiveClientCount(): number {
	let count = 0;
	for (const arr of clients.values()) {
		count += arr.length;
	}
	return count;
}
