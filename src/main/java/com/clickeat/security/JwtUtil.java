package com.clickeat.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * JWT utility for ClickEat Merchant API. Tokens are signed with HS256 and carry
 * claims: merchantId, email, role.
 */
public final class JwtUtil {

    /**
     * CHANGE THIS IN PRODUCTION – must be at least 256 bits (32 chars). Load
     * from env variable: System.getenv("JWT_SECRET")
     */
    private static final String SECRET
            = System.getenv("JWT_SECRET") != null
            ? System.getenv("JWT_SECRET")
            : "ClickEat-Secret-Key-2024-MUST-BE-32-CHARS!";

    /**
     * Token validity: 8 hours
     */
    private static final long EXPIRATION_MS = 8L * 60 * 60 * 1000;

    private static final SecretKey KEY
            = Keys.hmacShaKeyFor(SECRET.getBytes(StandardCharsets.UTF_8));

    private JwtUtil() {
    }

    /**
     * Generate a signed JWT for a merchant.
     */
    public static String generateToken(long merchantId, String email) {
        return Jwts.builder()
                .subject(String.valueOf(merchantId))
                .claim("email", email)
                .claim("role", "MERCHANT")
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + EXPIRATION_MS))
                .signWith(KEY)
                .compact();
    }

    /**
     * Validate token; returns false if expired or tampered.
     */
    public static boolean validateToken(String token) {
        try {
            parseClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    /**
     * Extract merchantId (subject) from valid token.
     */
    public static long extractMerchantId(String token) {
        return Long.parseLong(parseClaims(token).getSubject());
    }

    /**
     * Extract email claim.
     */
    public static String extractEmail(String token) {
        return parseClaims(token).get("email", String.class);
    }

    private static Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(KEY)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
