package com.clickeat.service;

import com.clickeat.dao.MerchantDAO;
import com.clickeat.model.Merchant;
import com.clickeat.security.JwtUtil;
import com.clickeat.util.OtpStore;
import com.clickeat.util.SmsService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.mindrot.jbcrypt.BCrypt;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

public class AuthService {

    private final MerchantDAO merchantDAO = new MerchantDAO();

    /**
     * Google Client ID – replace with your own from
     * https://console.cloud.google.com/ Authorized JS origins:
     * http://localhost:8080 and http://localhost:3000
     */
    private static final String GOOGLE_CLIENT_ID
            = System.getProperty("google.client.id",
                    System.getenv("GOOGLE_CLIENT_ID") != null
                    ? System.getenv("GOOGLE_CLIENT_ID")
                    : "791985931467-agv6l5lr044fihqsqbba65dp028cvdqc.apps.googleusercontent.com");

    // ----------------------------------------------------------------- login
    public Map<String, Object> login(String email, String password) throws SQLException, Exception {
        Optional<Merchant> opt = merchantDAO.findByEmail(email);
        if (opt.isEmpty()) {
            System.err.println("[Auth] No MERCHANT found with email: " + email);
            return null;
        }

        Merchant m = opt.get();
        if (!"ACTIVE".equals(m.getUserStatus())) {
            System.err.println("[Auth] User status is '" + m.getUserStatus() + "', not ACTIVE. email=" + email);
            return null;
        }
        if (!merchantDAO.verifyPassword(password, m.getPasswordHash())) {
            System.err.println("[Auth] Password mismatch for email: " + email);
            return null;
        }

        String token = JwtUtil.generateToken(m.getUserId(), m.getEmail());

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("token", token);
        result.put("merchantId", m.getUserId());
        result.put("name", m.getFullName());
        result.put("shopName", m.getShopName());
        result.put("email", m.getEmail());
        result.put("shopStatus", m.getShopStatus());
        return result;
    }

    // ----------------------------------------------------------- google login
    /**
     * Verify a Google ID token via Google's tokeninfo endpoint, then log in the
     * matching MERCHANT account (matched by email).
     */
    @SuppressWarnings("unchecked")
    public Map<String, Object> googleLogin(String credential) throws Exception {
        HttpClient http = HttpClient.newHttpClient();
        HttpRequest req = HttpRequest.newBuilder()
                .uri(URI.create("https://oauth2.googleapis.com/tokeninfo?id_token=" + credential))
                .GET().build();
        HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString());
        if (res.statusCode() != 200) {
            System.err.println("[Auth/Google] tokeninfo returned " + res.statusCode());
            return null;
        }
        Map<String, Object> tokenInfo = new ObjectMapper().readValue(res.body(), Map.class);

        // Validate audience
        String aud = (String) tokenInfo.get("aud");
        if (!GOOGLE_CLIENT_ID.equals(aud)) {
            System.err.println("[Auth/Google] aud mismatch: " + aud);
            return null;
        }

        String email = (String) tokenInfo.get("email");
        if (email == null) {
            return null;
        }

        Optional<Merchant> opt = merchantDAO.findByEmail(email);
        if (opt.isEmpty()) {
            System.err.println("[Auth/Google] No merchant found for email: " + email);
            // Return profile info so the frontend can pre-fill the registration form
            String googleName = (String) tokenInfo.getOrDefault("name", "");
            Map<String, Object> notReg = new LinkedHashMap<>();
            notReg.put("notRegistered", true);
            notReg.put("email", email);
            notReg.put("name", googleName);
            return notReg;
        }
        Merchant m = opt.get();
        if (!"ACTIVE".equals(m.getUserStatus())) {
            return null;
        }

        String token = JwtUtil.generateToken(m.getUserId(), m.getEmail());
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("token", token);
        result.put("merchantId", m.getUserId());
        result.put("name", m.getFullName());
        result.put("shopName", m.getShopName());
        result.put("email", m.getEmail());
        result.put("shopStatus", m.getShopStatus());
        return result;
    }

    // -------------------------------------------------------- forgot password
    /**
     * Generate and "send" (log) an OTP to the phone number. Returns true if
     * phone belongs to an active merchant.
     */
    public boolean forgotPassword(String phone) throws SQLException {
        Optional<Merchant> opt = merchantDAO.findByPhone(phone);
        if (opt.isEmpty() || !"ACTIVE".equals(opt.get().getUserStatus())) {
            return false;
        }
        OtpStore.invalidate(phone); // reset any previous OTP
        String otp = OtpStore.generate(phone);
        SmsService.sendOtp(phone, otp);
        return true;
    }

    // --------------------------------------------------------- reset password
    /**
     * Verify OTP and update password. Returns true on success.
     */
    public boolean resetPassword(String phone, String otp, String newPassword) throws SQLException {
        if (!OtpStore.verify(phone, otp)) {
            return false;
        }
        Optional<Merchant> opt = merchantDAO.findByPhone(phone);
        if (opt.isEmpty()) {
            return false;
        }
        String newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt(10));
        // reuse existing updatePassword method via the DAO
        merchantDAO.updatePassword(opt.get().getUserId(), newHash);
        return true;
    }

    // --------------------------------------------------------------- register
    /**
     * Minimal registration: creates dbo.Users + dbo.MerchantProfiles
     * (status=PENDING). Reads: fullName, email, password, phone, shopName,
     * shopPhone, shopAddressLine from body.
     */
    public Map<String, Object> register(String fullName, String email, String password,
            String phone, String shopName, String shopPhone,
            String shopAddressLine) throws SQLException {
        if (merchantDAO.findByEmail(email).isPresent()) {
            return null; // email taken
        }
        long newId = merchantDAO.create(fullName, email, password, phone,
                shopName, shopPhone, shopAddressLine,
                "", "", "", "", "", "");

        String token = JwtUtil.generateToken(newId, email);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("token", token);
        result.put("merchantId", newId);
        result.put("name", fullName);
        result.put("shopName", shopName);
        result.put("email", email);
        result.put("shopStatus", "PENDING");
        return result;
    }
}
