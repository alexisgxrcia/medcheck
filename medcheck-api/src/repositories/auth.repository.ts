import { executeQuery } from "@/config/database";
import type { DbUser } from "@/types";

export async function findUserByProviderId(
  providerId: string,
): Promise<DbUser | null> {
  const rows = await executeQuery<DbUser>(
    "SELECT * FROM users WHERE provider = 'google' AND provider_id = $1",
    [providerId],
  );
  return rows.length > 0 ? rows[0] : null;
}

export async function findUserById(id: string): Promise<DbUser | null> {
  const rows = await executeQuery<DbUser>("SELECT * FROM users WHERE id = $1", [
    id,
  ]);
  return rows.length > 0 ? rows[0] : null;
}

export async function updateUser(
  id: string,
  email: string,
  displayName?: string,
  timezone?: string,
): Promise<void> {
  await executeQuery(
    `UPDATE users SET email = $1, display_name = COALESCE($2, display_name),
		 timezone = COALESCE($3, timezone), updated_at = NOW() WHERE id = $4`,
    [email, displayName, timezone, id],
  );
}

export async function updateUserProfile(
  id: string,
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
  const updates: string[] = [];
  const values: unknown[] = [];

  for (const [key, value] of Object.entries(data)) {
    if (value === undefined) continue;
    values.push(value);
    updates.push(`${key} = $${values.length}`);
  }

  if (updates.length === 0) {
    const rows = await executeQuery<DbUser>("SELECT * FROM users WHERE id = $1", [
      id,
    ]);
    return rows[0] ?? null;
  }

  values.push(id);
  const rows = await executeQuery<DbUser>(
    `UPDATE users SET ${updates.join(", ")}, updated_at = NOW()
     WHERE id = $${values.length}
     RETURNING *`,
    values,
  );
  return rows[0] ?? null;
}

export async function insertUser(
  email: string,
  displayName: string | null,
  providerId: string,
  timezone: string,
): Promise<DbUser> {
  const rows = await executeQuery<DbUser>(
    `INSERT INTO users (email, display_name, provider, provider_id, timezone)
		 VALUES ($1, $2, 'google', $3, $4)
		 RETURNING *`,
    [email, displayName, providerId, timezone],
  );
  return rows[0];
}
