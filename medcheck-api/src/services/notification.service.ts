import {
  deleteDeviceTokensByUser,
  upsertDeviceToken,
} from "@/repositories/notification.repository";
import { publishProcessPendingAlertsCommand } from "@/notifier/command-consumer";

export async function registerDeviceToken(
  userId: string,
  token: string,
  platform: string,
) {
  const deviceToken = await upsertDeviceToken(userId, token, platform);
  await publishProcessPendingAlertsCommand("device_token_registered");
  return deviceToken;
}

export async function unregisterDeviceTokens(userId: string) {
  await deleteDeviceTokensByUser(userId);
  await publishProcessPendingAlertsCommand("device_tokens_unregistered");
}
