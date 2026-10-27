import { admin } from "@/config/firebase";
import dayjs from "dayjs";
import utc from "dayjs/plugin/utc";
import {
  deleteDeviceTokenByToken,
  findDeviceTokensByUser,
  findPendingCaregiverAlerts,
  insertNotification,
} from "@/repositories/notification.repository";
import { buildMissedIntakeEmail, sendEmail } from "@/services/email.service";

dayjs.extend(utc);

export async function processNotificationCron() {
  console.log(
    `[CRON] Iniciando proceso de notificaciones: ${dayjs.utc().toISOString()}`,
  );
  if (!admin.apps.length) return;

  try {
    const alerts = await findPendingCaregiverAlerts();
    console.log(`[CRON] Alertas pendientes encontradas: ${alerts.length}`);

    if (alerts.length === 0) return;

    console.log(`[CRON] ${alerts.length} alerta(s) de cuidador pendiente(s)`);

    for (const alert of alerts) {
      const deviceTokens = await findDeviceTokensByUser(alert.caregiver_id);
      const patientLabel = alert.patient_name || "Tu paciente";
      const title = `⚠️ ${patientLabel} no ha tomado su medicamento`;
      const body = `${alert.medication_name} estaba programado y no se ha registrado como tomado.`;

      let pushStatus = "not_applicable";

      if (deviceTokens.length > 0) {
        let sentCount = 0;

        for (const deviceToken of deviceTokens) {
          try {
            await admin.messaging().send({
              token: deviceToken.token,
              notification: { title, body },
              data: {
                type: "caregiver_alert",
                intake_id: alert.intake_id ?? "",
                medication_id: alert.medication_id,
                patient_id: alert.patient_id,
              },
              android: {
                priority: "high",
                notification: {
                  channelId: "caregiver_alerts",
                  priority: "high",
                  sound: "default",
                },
              },
              apns: {
                payload: {
                  aps: {
                    alert: { title, body },
                    sound: "default",
                    badge: 1,
                    "content-available": 1,
                  },
                },
              },
            });
            sentCount += 1;
          } catch (pushErr: any) {
            if (
              pushErr.code === "messaging/registration-token-not-registered" ||
              pushErr.code === "messaging/invalid-registration-token"
            ) {
              console.warn(
                `[CRON] Token muerto eliminado: ${deviceToken.token.substring(0, 20)}...`,
              );
              await deleteDeviceTokenByToken(deviceToken.token);
            } else {
              console.error(
                `[CRON] Error enviando push a token ${deviceToken.token}:`,
                pushErr.message,
              );
            }
          }
        }

        if (sentCount > 0) {
          pushStatus = "sent";
          console.log(
            `[CRON] Push enviado a ${sentCount} dispositivo(s) del cuidador ${alert.caregiver_id} por medicamento "${alert.medication_name}"`,
          );
        } else {
          pushStatus = "failed";
        }
      } else {
        console.log(
          `[CRON] Cuidador ${alert.caregiver_id} sin device token, omitiendo push`,
        );
      }

      await insertNotification({
        userId: alert.caregiver_id,
        medicationId: alert.medication_id,
        intakeId: alert.intake_id,
        type: "caregiver_alert",
        title,
        body,
        pushStatus,
      });

      try {
        const { subject, html } = buildMissedIntakeEmail(
          alert.caregiver_name || "Cuidador",
          alert.patient_name || "Tu paciente",
          alert.medication_name,
          alert.scheduled_time_display,
          alert.intake_status === "skipped" ? "skipped" : "missed",
        );
        await sendEmail({
          to: alert.caregiver_email,
          subject,
          html,
        });
        console.log(
          `[CRON] Email enviado a cuidador ${alert.caregiver_id} por medicamento "${alert.medication_name}"`,
        );
      } catch (emailErr: any) {
        console.error(
          `[CRON] Error enviando email a ${alert.caregiver_email}:`,
          emailErr.message,
        );
      }
    }
  } catch (err) {
    console.error("[CRON] Error en processNotificationCron:", err);
  }
}
