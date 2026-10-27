import type { NextFunction, Response } from "express";
import jwt from "jsonwebtoken";
import { config } from "@/config/config";
import { findUserById } from "@/repositories/auth.repository";
import type { AuthenticatedRequest } from "@/types";

export async function authMiddleware(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    res.status(401).json({ error: "Token requerido" });
    return;
  }

  const token = authHeader.slice(7);
  try {
    const decoded = jwt.verify(token, config.jwtSecret) as {
      userId: string;
    };

    const user = await findUserById(decoded.userId);
    if (user == null) {
      res.status(401).json({ error: "Usuario no encontrado" });
      return;
    }

    req.userId = decoded.userId;
    next();
  } catch {
    res.status(401).json({ error: "Token inválido o expirado" });
  }
}
