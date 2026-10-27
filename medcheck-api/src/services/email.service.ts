import { Resend } from "resend";
import { z } from "zod";
import { config } from "@/config/config";

const emailSchema = z.email();

const resend = new Resend(config.resendApiKey);

interface EmailParams {
  to: string;
  subject: string;
  html: string;
}

export async function sendEmail(params: EmailParams): Promise<boolean> {
  const parsed = emailSchema.safeParse(params.to);
  if (!parsed.success) {
    console.warn(`[EMAIL] Correo inválido: ${params.to}`);
    return false;
  }

  if (!config.resendApiKey) {
    console.warn("[EMAIL] RESEND_API_KEY no configurada, omitiendo envío");
    return false;
  }

  try {
    await resend.emails.send({
      from: "MedCheck <send@example.com>",
      to: params.to,
      subject: params.subject,
      html: params.html,
    });

    return true;
  } catch (err) {
    console.error(`[EMAIL] Excepción enviando a ${params.to}:`, err);
    return false;
  }
}

export function buildAppInvitationEmail(
  inviterName: string | null,
  _targetEmail: string,
  role: "patient" | "caregiver",
): { subject: string; html: string } {
  const roleText = role === "caregiver" ? "cuidador" : "paciente";
  const inviterText = inviterName || "Alguien";
  const roleLabel = role === "caregiver" ? "Cuidador" : "Paciente";
  const roleDescription =
    role === "caregiver"
      ? "Podras acompañar recordatorios, revisar el seguimiento y apoyar en el control de medicamentos."
      : "Podras recibir ayuda con el seguimiento de tus medicamentos y compartir tu progreso de forma sencilla.";

  const subject = `${inviterText} te invitó a MedCheck`;

  const html = `
<!DOCTYPE html>
<html>
<head>
	<style>
		@import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;700&display=swap');
	</style>
</head>
<body style="margin: 0; padding: 0; background-color: #F3F4F4; font-family: 'DM Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #161613;">
	<div style="max-width: 480px; margin: 40px auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.03);">
		<div style="height: 6px; background-color: #A294F9; width: 100%;"></div>
		<div style="padding: 40px 32px;">
			<h1 style="margin: 0 0 32px; font-family: Georgia, serif; font-size: 24px; color: #A294F9; letter-spacing: -0.5px;">MedCheck</h1>

			<h2 style="margin: 0 0 16px; font-family: Georgia, serif; font-size: 22px; color: #161613;">Hola,</h2>

			<p style="margin: 0 0 32px; font-size: 16px; line-height: 1.6; color: #4E4D4B;">
				<strong>${inviterText}</strong> te ha invitado a unirte a <span style="color: #A294F9; font-weight: 700;">MedCheck</span> como <strong>${roleText}</strong>.
			</p>

			<div style="border-left: 3px solid #CDC1FF; padding-left: 16px; margin-bottom: 24px;">
				<p style="margin: 0 0 4px; font-size: 12px; color: #9A9896; font-weight: 500; text-transform: uppercase; letter-spacing: 0.5px;">Rol</p>
				<p style="margin: 0 0 12px; font-size: 18px; font-weight: 700; color: #161613;">${roleLabel}</p>
				<p style="margin: 0; font-size: 14px; line-height: 1.7; color: #4E4D4B;">
					${roleDescription}
				</p>
			</div>

			<div style="margin-bottom: 32px; padding: 20px; background-color: #F8F7FF; border-radius: 14px;">
				<p style="margin: 0 0 12px; font-size: 12px; color: #9A9896; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px;">Como empezar</p>
				<p style="margin: 0 0 8px; font-size: 14px; line-height: 1.6; color: #4E4D4B;">1. Descarga la app en tu celular.</p>
				<p style="margin: 0 0 8px; font-size: 14px; line-height: 1.6; color: #4E4D4B;">2. Inicia sesion o crea tu cuenta con este mismo correo.</p>
				<p style="margin: 0; font-size: 14px; line-height: 1.6; color: #4E4D4B;">3. Una vez dentro, podras continuar con la vinculacion y comenzar a usar MedCheck.</p>
			</div>

			<div style="margin-bottom: 40px; text-align: center;">
        <a
          href="https://example.com/#descarga"
          target="_blank"
          style="display: inline-block; padding: 16px 32px; background-color: #A294F9; color: #ffffff; text-decoration: none; border-radius: 12px; font-weight: 700; font-size: 16px;"
        >
          Descargar la app
        </a>
      </div>

			<div style="border-top: 1px solid #E8E8E8; padding-top: 24px;">
				<p style="margin: 0 0 10px; font-size: 13px; color: #9A9896; line-height: 1.6;">
					Descarga MedCheck para aceptar esta invitacion y comenzar a gestionar medicamentos, recordatorios y seguimiento desde un solo lugar.
				</p>
				<p style="margin: 0; font-size: 13px; color: #9A9896; line-height: 1.6;">
					Si no esperabas esta invitacion, puedes ignorar este correo sin realizar ninguna accion.
				</p>
			</div>
		</div>
	</div>
</body>
</html>
	`;

  return { subject, html };
}

export function buildMissedIntakeEmail(
  caregiverName: string,
  userName: string,
  medicationName: string,
  timeOfDay: string,
  reason: "missed" | "skipped",
): { subject: string; html: string } {
  const action = reason === "skipped" ? "omitió" : "no ha tomado";
  const subject = `${userName} ${action} su medicamento: ${medicationName}`;

  const html = `
<!DOCTYPE html>
<html>
<head>
	<style>
		@import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;700&display=swap');
	</style>
</head>
<body style="margin: 0; padding: 0; background-color: #F3F4F4; font-family: 'DM Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #161613;">
	<div style="max-width: 480px; margin: 40px auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.03);">
		<div style="height: 6px; background-color: #A294F9; width: 100%;"></div>
		<div style="padding: 40px 32px;">
			<h1 style="margin: 0 0 32px; font-family: Georgia, serif; font-size: 24px; color: #A294F9; letter-spacing: -0.5px;">MedCheck</h1>

			<h2 style="margin: 0 0 16px; font-family: Georgia, serif; font-size: 22px; color: #161613;">Hola ${caregiverName},</h2>

			<p style="margin: 0 0 32px; font-size: 16px; line-height: 1.6; color: #4E4D4B;">
				${
          reason === "skipped"
            ? `<strong>${userName}</strong> ha <span style="color: #A294F9; font-weight: 700;">omitido</span> su toma programada.`
            : `<strong>${userName}</strong> <span style="color: #A294F9; font-weight: 700;">no ha registrado</span> su toma programada.`
        }
			</p>

			<div style="border-left: 3px solid #CDC1FF; padding-left: 16px; margin-bottom: 40px;">
				<p style="margin: 0 0 4px; font-size: 12px; color: #9A9896; font-weight: 500; text-transform: uppercase; letter-spacing: 0.5px;">Medicamento</p>
				<p style="margin: 0 0 16px; font-size: 18px; font-weight: 700; color: #161613;">${medicationName}</p>

				<p style="margin: 0 0 4px; font-size: 12px; color: #9A9896; font-weight: 500; text-transform: uppercase; letter-spacing: 0.5px;">Hora programada</p>
				<p style="margin: 0; font-size: 18px; font-weight: 700; color: #161613;">${timeOfDay}</p>
			</div>

			<div style="border-top: 1px solid #E8E8E8; padding-top: 24px;">
				<p style="margin: 0; font-size: 13px; color: #9A9896; line-height: 1.5;">
					Este mensaje es automático. Por favor, verifica el estado del paciente.
				</p>
			</div>
		</div>
	</div>
</body>
</html>
	`;

  return { subject, html };
}
