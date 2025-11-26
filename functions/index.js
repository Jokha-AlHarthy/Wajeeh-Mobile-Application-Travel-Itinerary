const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
        user: "joker2002187@gmail.com",
        pass: "lxbp blos resl pjsp",
    },
});

exports.sendOtpEmail = functions.https.onCall(async (data, context) => {
    const { email, otp } = data;

    const mailOptions = {
        from: "Wajeeh App <YOUR_GMAIL@gmail.com>",
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
