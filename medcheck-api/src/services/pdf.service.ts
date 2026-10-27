import PDFDocument from "pdfkit";
import dayjs from "dayjs";
import utc from "dayjs/plugin/utc";
import timezone from "dayjs/plugin/timezone";
import "dayjs/locale/es";

dayjs.extend(utc);
dayjs.extend(timezone);

interface Medication {
  name: string;
  dosage?: string | null;
  notes?: string | null;
  start_date?: string | null;
  end_date?: string | null;
  frequency_type?: string;
  time_of_day?: string | null;
  days_of_week?: number[];
  interval_hours?: number | null;
  interval_days?: number | null;
}

interface IntakeRecord {
  scheduled_time: string;
  scheduled_time_of_day?: string | null;
  taken_at?: string | null;
  status: string;
  medication_name: string;
  medication_dosage?: string | null;
}

interface PatientReportData {
  patientName: string;
  caregiverName: string;
  patientEmail: string | null;
  patientBirthDate: string | null;
  patientWeightKg: number | null;
  patientHeightCm: number | null;
  patientTimezone: string | null;
  generatedAt: string;
  medications: Medication[];
  history: IntakeRecord[];
}

const COLORS = {
  primary: "#A294F9",
  dark: "#161613",
  secondary: "#4E4D4B",
  muted: "#9A9896",
  light: "#CDC1FF",
  bg: "#F3F4F4",
  white: "#FFFFFF",
};

export function buildPatientReportPDF(data: PatientReportData): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    dayjs.locale("es");
    const reportTimezone = data.patientTimezone || "America/Mazatlan";

    const doc = new PDFDocument({ margin: 50, size: "A4" });
    const chunks: Buffer[] = [];

    doc.on("data", (chunk: Buffer) => chunks.push(chunk));
    doc.on("end", () => resolve(Buffer.concat(chunks)));
    doc.on("error", reject);

    doc.rect(0, 0, doc.page.width, 8).fill(COLORS.primary);

  doc.moveDown(1.5);
  doc.fontSize(24).fillColor(COLORS.primary).font("Helvetica-Bold");
  doc.text("MedCheck", 50, doc.y);

  doc.moveDown(0.5);
  doc.fontSize(18).fillColor(COLORS.dark).font("Helvetica-Bold");
  doc.text("Informe del Paciente");

  doc.moveDown(0.8);
  const infoY = doc.y;
  doc.rect(50, infoY, doc.page.width - 100, 70).fill(COLORS.bg);

  doc.fillColor(COLORS.dark).fontSize(12).font("Helvetica-Bold");
  doc.text(`Paciente: ${data.patientName}`, 65, infoY + 15);
  doc.fillColor(COLORS.secondary).fontSize(11).font("Helvetica");
  doc.text(`Generado por: ${data.caregiverName}`, 65, infoY + 35);
  doc.text(
    `Fecha del informe: ${formatDateTime12h(data.generatedAt, reportTimezone)}`,
    65,
    infoY + 50,
  );

  doc.moveDown(3.5);

  doc.fontSize(16).fillColor(COLORS.dark).font("Helvetica-Bold");
  doc.text("Datos del Paciente");

  doc.moveDown(0.3);
  doc.strokeColor(COLORS.light).lineWidth(2);
  doc.moveTo(50, doc.y).lineTo(doc.page.width - 50, doc.y).stroke();
  doc.moveDown(0.5);

  const patientFields = [
    `Correo: ${data.patientEmail || "No definido"}`,
    `Cumpleaños: ${formatBirthDate(data.patientBirthDate)}`,
    `Edad: ${formatAge(data.patientBirthDate)}`,
    `Peso: ${formatMeasurement(data.patientWeightKg, "kg")}`,
    `Altura: ${formatMeasurement(data.patientHeightCm, "cm")}`,
  ];

  doc.fontSize(11).fillColor(COLORS.secondary).font("Helvetica");
  for (const field of patientFields) {
    doc.text(field, { indent: 10 });
    doc.moveDown(0.2);
  }

  doc.moveDown(0.8);

  doc.fontSize(16).fillColor(COLORS.dark).font("Helvetica-Bold");
  doc.text("Medicamentos Activos");

  doc.moveDown(0.3);
  doc.strokeColor(COLORS.light).lineWidth(2);
  doc.moveTo(50, doc.y).lineTo(doc.page.width - 50, doc.y).stroke();
  doc.moveDown(0.5);

  if (data.medications.length === 0) {
    doc.fontSize(12).fillColor(COLORS.muted).font("Helvetica");
    doc.text("No hay medicamentos registrados.");
  } else {
    for (const med of data.medications) {
      doc.fontSize(13).fillColor(COLORS.dark).font("Helvetica-Bold");
      doc.text(med.name, { indent: 10 });

      const details: string[] = [];
      if (med.dosage) details.push(`Dosis: ${med.dosage}`);
      if (med.frequency_type) {
        details.push(`Frecuencia: ${formatFrequencyLabel(med)}`);
      }
      if (med.time_of_day && med.frequency_type !== "interval") {
        details.push(`Hora: ${formatTimeOfDay12h(med.time_of_day)}`);
      }
      if (med.start_date) details.push(`Inicio: ${dayjs(med.start_date).format("DD/MM/YYYY")}`);

      doc.fontSize(11).fillColor(COLORS.secondary).font("Helvetica");
      doc.text(details.join("  |  "), { indent: 10 });

      if (med.notes) {
        doc.fontSize(10).fillColor(COLORS.muted).font("Helvetica-Oblique");
        doc.text(`Notas: ${med.notes}`, { indent: 10 });
      }

      doc.moveDown(0.4);
    }
  }

  doc.moveDown(1);

  doc.fontSize(16).fillColor(COLORS.dark).font("Helvetica-Bold");
  doc.text("Historial de Tomas");

  doc.moveDown(0.3);
  doc.strokeColor(COLORS.light).lineWidth(2);
  doc.moveTo(50, doc.y).lineTo(doc.page.width - 50, doc.y).stroke();
  doc.moveDown(0.5);

  if (data.history.length === 0) {
    doc.fontSize(12).fillColor(COLORS.muted).font("Helvetica");
    doc.text("No hay registros de tomas.");
  } else {
    const grouped = groupHistoryByDate(data.history, reportTimezone);

    for (const [date, records] of Object.entries(grouped)) {
      doc.fontSize(12).fillColor(COLORS.primary).font("Helvetica-Bold");
      doc.text(dayjs(date).format("dddd, DD [de] MMMM [de] YYYY"), { indent: 5 });
      doc.moveDown(0.2);

      for (const record of records) {
        const statusColor = getStatusColor(record.status);
        const statusLabel = getStatusLabel(record.status);

        doc.fontSize(11).fillColor(COLORS.dark).font("Helvetica-Bold");
        doc.text(record.medication_name, { indent: 15, continued: true });

        doc.fillColor(statusColor).font("Helvetica-Bold");
        doc.text(`  ${statusLabel}`, { align: "right" });

        doc.fontSize(10).fillColor(COLORS.secondary).font("Helvetica");
        const timeStr = getScheduledTimeLabel(record, reportTimezone);
        let detailText = `Programado: ${timeStr}`;
        if (record.taken_at) {
          detailText += `  |  Tomado: ${formatDateTimeTimeOnly12h(record.taken_at, reportTimezone)}`;
        }
        if (record.medication_dosage) {
          detailText += `  |  ${record.medication_dosage}`;
        }
        doc.text(detailText, { indent: 15 });
        doc.moveDown(0.3);
      }

      doc.moveDown(0.5);
    }
  }

  doc.moveDown(2);
  doc.strokeColor(COLORS.light).lineWidth(1);
  doc.moveTo(50, doc.y).lineTo(doc.page.width - 50, doc.y).stroke();
  doc.moveDown(0.5);
  doc.fontSize(10).fillColor(COLORS.muted).font("Helvetica");
  doc.text(
    "Este informe fue generado automáticamente por MedCheck.",
    { align: "center" },
  );

    doc.end();
  });
}

function groupHistoryByDate(
  history: IntakeRecord[],
  timezoneName: string,
): Record<string, IntakeRecord[]> {
  const grouped: Record<string, IntakeRecord[]> = {};
  for (const record of history) {
    const date = toTimezone(record.scheduled_time, timezoneName).format(
      "YYYY-MM-DD",
    );
    if (!grouped[date]) grouped[date] = [];
    grouped[date].push(record);
  }
  return grouped;
}

function getScheduledTimeLabel(
  record: IntakeRecord,
  timezoneName: string,
): string {
  const scheduled = toTimezone(record.scheduled_time, timezoneName);
  const scheduledTime = scheduled.format("h:mm a").toLowerCase();

  if (
    scheduled.format("HH:mm") === "00:00" &&
    record.scheduled_time_of_day &&
    record.scheduled_time_of_day.length >= 4
  ) {
    return formatTimeOfDay12h(record.scheduled_time_of_day);
  }

  return scheduledTime;
}

function formatDateTime12h(value: string, timezoneName: string): string {
  return toTimezone(value, timezoneName).format("DD/MM/YYYY h:mm a").toLowerCase();
}

function formatDateTimeTimeOnly12h(value: string, timezoneName: string): string {
  return toTimezone(value, timezoneName).format("h:mm a").toLowerCase();
}

function toTimezone(value: string, timezoneName: string) {
  return dayjs.utc(value).tz(timezoneName);
}

function formatTimeOfDay12h(value: string): string {
  const parts = value.split(":");
  if (parts.length < 2) return value;
  const hour = Number(parts[0]);
  const minute = Number(parts[1]);
  if (Number.isNaN(hour) || Number.isNaN(minute)) return value;

  const normalizedHour = ((hour + 11) % 12) + 1;
  const suffix = hour >= 12 ? "pm" : "am";
  const minuteLabel = minute.toString().padStart(2, "0");
  return `${normalizedHour}:${minuteLabel} ${suffix}`;
}

function formatFrequencyLabel(med: Medication): string {
  switch (med.frequency_type) {
    case "daily":
      return "Todos los días";
    case "weekly":
      return formatWeeklyLabel(med.days_of_week ?? []);
    case "interval":
      return `Cada ${med.interval_hours ?? 1} horas`;
    case "everyXDays":
      return `Cada ${med.interval_days ?? 1} días`;
    case "prn":
      return "Según necesidad";
    default:
      return med.frequency_type ?? "No definida";
  }
}

function formatWeeklyLabel(daysOfWeek: number[]): string {
  if (daysOfWeek.length === 0) return "Semanal";

  const normalized = [...daysOfWeek].sort((a, b) => a - b);
  if (normalized.length === 7) return "Todos los días";

  const dayNames = [
    "domingo",
    "lunes",
    "martes",
    "miércoles",
    "jueves",
    "viernes",
    "sábado",
  ];

  const labels = normalized.map((day) => dayNames[day % 7]);
  return `Cada ${joinLabels(labels)}`;
}

function joinLabels(labels: string[]): string {
  if (labels.length === 0) return "";
  if (labels.length === 1) return labels[0];
  if (labels.length === 2) return `${labels[0]} y ${labels[1]}`;
  return `${labels.slice(0, -1).join(", ")} y ${labels[labels.length - 1]}`;
}

function getStatusColor(status: string): string {
  switch (status) {
    case "taken":
      return "#4CAF50";
    case "skipped":
      return "#FF9800";
    case "missed":
      return "#F44336";
    default:
      return COLORS.muted;
  }
}

function getStatusLabel(status: string): string {
  switch (status) {
    case "taken":
      return "Tomado";
    case "skipped":
      return "Omitido";
    case "missed":
      return "Perdido";
    default:
      return status;
  }
}

function formatBirthDate(value: string | null): string {
  if (!value) return "No definido";
  const date = dayjs(value);
  return date.isValid() ? date.format("DD/MM/YYYY") : "No definido";
}

function formatAge(value: string | null): string {
  if (!value) return "No definido";
  const birthDate = dayjs(value);
  if (!birthDate.isValid()) return "No definido";

  const years = dayjs().diff(birthDate, "year");
  return years >= 0 ? `${years} años` : "No definido";
}

function formatMeasurement(
  value: number | null,
  unit: string,
): string {
  if (value == null) return "No definido";
  return `${value} ${unit}`;
}
