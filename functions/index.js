const { onCall ,HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const crypto = require("crypto");

admin.initializeApp();


const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "joker2002187@gmail.com",
    pass: "lxbp blos resl pjsp",
  },
});


exports.sendOtpEmail = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("User must be authenticated");
  }

  const { email, otp } = request.data;

  if (!email || !otp) {
    throw new Error("Email and OTP are required");
  }

  const mailOptions = {
    from: "Wajeeh App <joker2002187@gmail.com>",
    to: email,
    subject: "Your Wajeeh OTP Code",
    html: `
      <p>Your OTP code is:</p>
      <h1 style="font-size: 36px;">${otp}</h1>
      <p>Use this code to verify your account.</p>
    `,
  };

  await transporter.sendMail(mailOptions);

  return { success: true };
});



exports.deleteUserByAdmin = onCall(async (request) => {


  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const callerUid = request.auth.uid;
  const targetUid = request.data.uid;

  if (!targetUid) {
    throw new HttpsError("invalid-argument", "UID is required");
  }


  if (callerUid === targetUid) {
    throw new HttpsError(
      "permission-denied",
      "Admin cannot delete himself"
    );
  }


  const callerDoc = await admin
    .firestore()
    .collection("users")
    .doc(callerUid)
    .get();

  if (!callerDoc.exists || callerDoc.data().role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Only admins can delete users"
    );
  }

  try {

    await admin.auth().deleteUser(targetUid);

  } catch (error) {
    if (error.code !== "auth/user-not-found") {
      throw new HttpsError("internal", error.message);
    }
  }

  await admin
    .firestore()
    .collection("users")
    .doc(targetUid)
    .delete();

  return { success: true };
});

exports.createUserWithResetEmail = onCall(
  { region: "us-central1" },
  async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const callerUid = request.auth.uid;
  const callerDoc = await admin
    .firestore()
    .collection("users")
    .doc(callerUid)
    .get();

  if (!callerDoc.exists || callerDoc.data().role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Only admins can add users"
    );
  }

  const { fullName, email, role, forcePasswordChange } = request.data || {};

  if (!email || !fullName || !role) {
    throw new HttpsError(
      "invalid-argument",
      "fullName, email, and role are required"
    );
  }

  const trimmedEmail = String(email).trim();
  const trimmedName = String(fullName).trim();
  const normalizedRole = String(role).toLowerCase();

  if (normalizedRole !== "user" && normalizedRole !== "admin") {
    throw new HttpsError("invalid-argument", "Invalid role");
  }

  const tempPassword = crypto.randomBytes(32).toString("base64url");

  let uid;
  try {
    const userRecord = await admin.auth().createUser({
      email: trimmedEmail,
      password: tempPassword,
      emailVerified: false,
    });
    uid = userRecord.uid;
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
        "already-exists",
        "This email is already registered"
      );
    }
    throw new HttpsError("internal", error.message || "Failed to create user");
  }

  try {
    await admin.firestore().collection("users").doc(uid).set({
      uid,
      fullName: trimmedName,
      email: trimmedEmail,
      role: normalizedRole,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      forcePasswordChange: Boolean(forcePasswordChange),
    });
  } catch (e) {
    await admin.auth().deleteUser(uid).catch(() => {});
    throw new HttpsError("internal", e.message || "Failed to save user profile");
  }

  try {
    const link = await admin.auth().generatePasswordResetLink(trimmedEmail);
    await transporter.sendMail({
      from: "Wajeeh App <joker2002187@gmail.com>",
      to: trimmedEmail,
      subject: "Set your Wajeeh account password",
      html: `
        <p>Welcome to Wajeeh! An administrator created an account for you.</p>
        <p>Click the link below to set your password and sign in:</p>
        <p><a href="${link}">Set my password</a></p>
        <p>If you did not expect this email, you can ignore it.</p>
      `,
    });
  } catch (e) {
    console.error("createUserWithResetEmail: email failed", e);
    await admin.auth().deleteUser(uid).catch(() => {});
    await admin.firestore().collection("users").doc(uid).delete().catch(() => {});
    throw new HttpsError(
      "internal",
      "User was not created because the password reset email could not be sent"
    );
  }

  return { success: true };
  }
);

const { onSchedule } = require("firebase-functions/v2/scheduler");

exports.sendInactiveNotification = onSchedule(
  "every 24 hours",
  async (event) => {
    const db = admin.firestore();

    const thirtyDaysAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    );

    const users = await db
      .collection("users")
      .where("lastSeen", "<=", thirtyDaysAgo)
      .get();

    for (const doc of users.docs) {
      const data = doc.data();
      if (!data.deviceToken) continue;

      try {
        await admin.messaging().send({
          token: data.deviceToken,
          notification: {
            title: "We missed you ✈️",
            body: "Come back and plan your trip with us 🌍",
          },
        });
      } catch (err) {
        console.error("Failed to notify", doc.id, err.message);
      }
    }
  });

  const { Translate } = require("@google-cloud/translate").v2;

  const translator = new Translate();

  exports.translateFeedback = onCall(
    {
      region: "us-central1",
    },
    async (request) => {
      try {
        const text = request.data?.text;
        const targetLanguage = request.data?.targetLanguage || "ar";

        if (!text) {
          throw new HttpsError("invalid-argument", "Text is required");
        }

        const [translation] = await translator.translate(text, targetLanguage);

        return {
          translatedText: translation,
        };
      } catch (error) {
        console.error(error);
        throw new HttpsError("internal", "Translation failed");
      }
    }
  );
