const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.generateCaregiverCode = functions.https.onCall(
    async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "You must be logged in to generate a code.",
        );
      }

      const patientId = context.auth.uid;

      const secretCode = Math.floor(100000 + Math.random() * 900000).toString();

      const expirationDate = new Date();
      expirationDate.setHours(expirationDate.getHours() + 24);

      await admin.firestore().collection("linking_codes").doc(secretCode).set({
        patientId: patientId,
        expiresAt: expirationDate,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        code: secretCode,
        message: "Code generated successfully!",
      };
    },
);
