package com.clickeat.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * SMS service for sending OTPs.
 *
 * PRODUCTION: Replace the body of sendOtp() with a call to your SMS provider,
 * e.g. Twilio, ESMS.vn, SpeedSMS, etc.
 *
 * Twilio example: Twilio.init(ACCOUNT_SID, AUTH_TOKEN); Message.creator(new
 * PhoneNumber("+84" + phone.substring(1)), new PhoneNumber(TWILIO_FROM), "Mã
 * OTP ClickEat của bạn là: " + otp + ". Hiệu lực 5 phút.") .create();
 */
public final class SmsService {

    private static final Logger log = LoggerFactory.getLogger(SmsService.class);

    private SmsService() {
    }

    /**
     * Send OTP SMS to the given Vietnamese phone number. Currently logs to
     * console (dev/demo mode).
     */
    public static void sendOtp(String phone, String otp) {
        String message = "Mã OTP ClickEat của bạn là: " + otp + ". Hiệu lực 5 phút. Không chia sẻ mã này.";

        // ── DEV MODE: log instead of sending ──────────────────────────────
        log.info("[SMS-OTP] → {} | {}", phone, message);
        System.out.println("╔══════════════════════════════════════════════");
        System.out.println("║ [ClickEat SMS – DEV MODE]");
        System.out.println("║ Gửi đến: " + phone);
        System.out.println("║ Nội dung: " + message);
        System.out.println("╚══════════════════════════════════════════════");
        // ──────────────────────────────────────────────────────────────────

        // TODO: Uncomment and configure for production:
        // twilioSend(phone, message);
    }
}
