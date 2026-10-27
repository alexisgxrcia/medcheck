import admin from "firebase-admin";
import { config } from "./config";

const raw = config.firebaseServiceAccount;

if (raw) {
  try {
    const serviceAccount = JSON.parse(raw);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log("Firebase Admin SDK inicializado correctamente");
  } catch (err) {
    console.error("Error al parsear FIREBASE_SERVICE_ACCOUNT:", err);
  }
} else {
  console.warn(
    "FIREBASE_SERVICE_ACCOUNT no configurado — push notifications deshabilitadas",
  );
}

export { admin };
