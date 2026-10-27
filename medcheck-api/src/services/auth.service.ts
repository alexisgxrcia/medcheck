import jwt from "jsonwebtoken";
import { config } from "@/config/config";
import {
  findUserByProviderId,
  insertUser,
  updateUser,
  updateUserProfile,
} from "@/repositories/auth.repository";
import type { DbUser } from "@/types";

interface GoogleTokenPayload {
  sub: string;
  email: string;
  name?: string;
}

export async function verifyGoogleToken(
  idToken: string,
): Promise<GoogleTokenPayload> {
  const res = await fetch(
    `https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`,
  );

  if (!res.ok) {
    throw new Error("Token de Google inválido");
  }

  const payload = (await res.json()) as GoogleTokenPayload & { aud?: string };
  const validClientIds = [
    config.googleClientId,
    config.googleClientIdIos,
    ...config.googleClientIdsAndroid,
  ].filter(Boolean);

  if (validClientIds.length > 0 && !validClientIds.includes(payload.aud ?? "")) {
    console.log("Audiencia del token no coincide. Esperado uno de:", {
      googleClientId: config.googleClientId,
      googleClientIdIos: config.googleClientIdIos,
      googleClientIdsAndroid: config.googleClientIdsAndroid,
    });
    console.log("Audiencia recibida:", payload.aud);
    throw new Error("Audience del token no coincide");
  }

  return payload;
}

export async function upsertUser(
  email: string,
  providerId: string,
  displayName?: string,
  timezone = "America/Mazatlan",
): Promise<{ user: DbUser; isNewUser: boolean }> {
  const existing = await findUserByProviderId(providerId);

  if (existing) {
    await updateUser(existing.id, email, displayName, timezone);
    return {
      user: {
        ...existing,
        email,
        display_name: displayName ?? existing.display_name,
        timezone,
      },
      isNewUser: false,
    };
  }

  return {
    user: await insertUser(email, displayName ?? null, providerId, timezone),
    isNewUser: true,
  };
}

export function generateJwt(userId: string, email: string): string {
  return jwt.sign({ userId, email }, config.jwtSecret, { expiresIn: "30d" });
}

export async function updateProfile(
  userId: string,
  data: {
    role?: string;
    display_name?: string | null;
    birth_date?: string | null;
    weight_kg?: number | null;
    height_cm?: number | null;
    timezone?: string | null;
    notifications_enabled?: boolean;
    dark_mode?: boolean;
  },
): Promise<DbUser | null> {
  return updateUserProfile(userId, data);
}
