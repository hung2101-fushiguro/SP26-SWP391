package com.clickeat.util;

import java.time.Instant;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;

/**
 * In-memory OTP store with 5-minute TTL.
 * One OTP per phone number at a time; verified OTP is immediately removed.
 */
public final class OtpStore {

    private record OtpEntry(String otp, Instant expiresAt) {}

    private static final ConcurrentHashMap<String, OtpEntry> STORE = new ConcurrentHashMap<>();
    private static final long TTL_SECONDS = 300; // 5 minutes
    private static final Random RNG = new Random();

    private OtpStore() {}

    /** Generate and store a new 6-digit OTP for the given phone. Returns the OTP. */
    public static String generate(String phone) {
        String otp = String.format("%06d", RNG.nextInt(1_000_000));
        STORE.put(phone, new OtpEntry(otp, Instant.now().plusSeconds(TTL_SECONDS)));
        return otp;
    }

    /**
     * Verify the OTP for a phone.
     * Returns true only if OTP matches and has not expired.
     * The entry is removed upon successful verification.
     */
    public static boolean verify(String phone, String otp) {
        OtpEntry entry = STORE.get(phone);
        if (entry == null) return false;
        if (Instant.now().isAfter(entry.expiresAt())) {
            STORE.remove(phone);
            return false;
        }
        if (!entry.otp().equals(otp)) return false;
        STORE.remove(phone);
        return true;
    }

    /** Remove leftover OTP (e.g. if user requests a new one). */
    public static void invalidate(String phone) {
        STORE.remove(phone);
    }
}
