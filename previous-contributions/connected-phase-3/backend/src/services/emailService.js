import sgMail from "@sendgrid/mail";
import { config } from "../config/env.js";

// Initialize SendGrid
if (config.sendgridApiKey) {
  sgMail.setApiKey(config.sendgridApiKey);
}

/**
 * Send email via SendGrid
 */
export async function sendEmail(to, subject, htmlContent, plainContent = null) {
  if (!config.sendgridApiKey || !config.notificationEmailFrom) {
    console.warn(
      "SendGrid not configured. Email would be sent to:",
      to,
      "Subject:",
      subject,
    );
    return {
      sent: false,
      reason: "SendGrid not configured",
    };
  }

  try {
    const msg = {
      to,
      from: config.notificationEmailFrom,
      subject,
      html: htmlContent,
      ...(plainContent && { text: plainContent }),
    };

    const response = await sgMail.send(msg);

    console.log(
      `Email sent to ${to} with messageId: ${response[0].headers["x-message-id"]}`,
    );

    return {
      sent: true,
      messageId: response[0].headers["x-message-id"],
    };
  } catch (error) {
    console.error("Error sending email:", error);
    throw error;
  }
}

/**
 * Send OTP verification email
 */
export async function sendOtpEmail(email, otp, type = "email") {
  const subject =
    type === "email"
      ? "VitalTrack Email Verification Code"
      : "VitalTrack Verification Code";

  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; background-color: #f5f5f5; }
        .container { max-width: 500px; margin: 0 auto; padding: 20px; background-color: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { color: #333; margin-bottom: 20px; }
        .otp-box { background-color: #f0f0f0; padding: 20px; border-radius: 4px; text-align: center; margin: 20px 0; }
        .otp { font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #2e7d32; }
        .footer { color: #999; font-size: 12px; margin-top: 20px; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2 class="header">Email Verification</h2>
        <p>Hello,</p>
        <p>Your verification code for VitalTrack is:</p>
        <div class="otp-box">
          <div class="otp">${otp}</div>
        </div>
        <p>This code expires in 5 minutes. Do not share it with anyone.</p>
        <p>If you didn't request this code, please ignore this email.</p>
        <hr />
        <p class="footer">© VitalTrack. All rights reserved.</p>
      </div>
    </body>
    </html>
  `;

  const plainContent = `Your VitalTrack verification code is: ${otp}\n\nThis code expires in 5 minutes.`;

  return sendEmail(email, subject, htmlContent, plainContent);
}

/**
 * Send caregiver linking notification email
 */
export async function sendCaregiverLinkingEmail(
  patientEmail,
  patientName,
  caregiverName,
) {
  const subject = "New Caregiver Linked to Your VitalTrack Account";

  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; background-color: #f5f5f5; }
        .container { max-width: 500px; margin: 0 auto; padding: 20px; background-color: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { color: #333; margin-bottom: 20px; }
        .info-box { background-color: #f0f8ff; padding: 15px; border-left: 4px solid #2196f3; margin: 20px 0; }
        .footer { color: #999; font-size: 12px; margin-top: 20px; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2 class="header">Caregiver Linked</h2>
        <p>Hello ${patientName},</p>
        <p>A new caregiver has been linked to your VitalTrack account:</p>
        <div class="info-box">
          <strong>Caregiver Name:</strong> ${caregiverName}
        </div>
        <p>This caregiver can now view your medical records and health data. If you didn't authorize this, please log in to your VitalTrack account to remove this caregiver.</p>
        <hr />
        <p class="footer">© VitalTrack. All rights reserved.</p>
      </div>
    </body>
    </html>
  `;

  return sendEmail(patientEmail, subject, htmlContent);
}

/**
 * Send medical alert email to caregivers
 */
export async function sendMedicalAlertEmail(
  caregiverEmail,
  caregiverName,
  patientName,
  alertType,
  details,
) {
  const subject = `VitalTrack Alert: ${alertType} for ${patientName}`;

  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; background-color: #f5f5f5; }
        .container { max-width: 500px; margin: 0 auto; padding: 20px; background-color: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { color: #d32f2f; margin-bottom: 20px; }
        .alert-box { background-color: #ffebee; padding: 15px; border-left: 4px solid #d32f2f; margin: 20px 0; }
        .footer { color: #999; font-size: 12px; margin-top: 20px; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2 class="header">⚠️ Medical Alert</h2>
        <p>Hello ${caregiverName},</p>
        <p>A medical alert has been triggered for your patient:</p>
        <div class="alert-box">
          <strong>Patient:</strong> ${patientName}<br />
          <strong>Alert Type:</strong> ${alertType}<br />
          <strong>Details:</strong> ${details}
        </div>
        <p>Please log in to VitalTrack to view more information and take appropriate action.</p>
        <hr />
        <p class="footer">© VitalTrack. All rights reserved.</p>
      </div>
    </body>
    </html>
  `;

  return sendEmail(caregiverEmail, subject, htmlContent);
}

export default {
  sendEmail,
  sendOtpEmail,
  sendCaregiverLinkingEmail,
  sendMedicalAlertEmail,
};
