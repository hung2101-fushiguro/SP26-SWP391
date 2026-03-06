package com.clickeat.servlet;

import com.clickeat.model.Merchant;
import com.clickeat.service.SettingsService;
import com.clickeat.util.JsonUtil;
import com.clickeat.util.ResponseUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.Map;

import java.util.Optional;

/**
 * GET /api/settings/profile â€“ get merchant profile PUT /api/settings/profile â€“
 * update profile POST /api/settings/change-password â€“ change password
 */
public class SettingsServlet extends HttpServlet {

    private final SettingsService settingsService = new SettingsService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        try {
            Optional<Merchant> m = settingsService.getProfile(merchantId);
            if (m.isPresent()) {
                // Strip password hash before sending
                Merchant profile = m.get();
                profile.setPasswordHash(null);
                ResponseUtil.ok(resp, profile);
            } else {
                ResponseUtil.notFound(resp, "Merchant not found");
            }
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }

    @Override
    protected void doPut(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        String pathInfo = req.getPathInfo();      // /profile

        if ("/profile".equals(pathInfo)) {
            try {
                @SuppressWarnings("unchecked")
                Map<String, String> body = JsonUtil.readBody(req, Map.class);
                String shopName = body.getOrDefault("shopName", "").trim();
                String shopPhone = body.getOrDefault("shopPhone", "");
                String shopAddressLine = body.getOrDefault("shopAddressLine", "");

                if (shopName.isEmpty()) {
                    ResponseUtil.badRequest(resp, "shopName is required");
                    return;
                }

                Merchant updated = settingsService.updateProfile(merchantId, shopName, shopPhone, shopAddressLine);
                updated.setPasswordHash(null);
                ResponseUtil.ok(resp, updated);
            } catch (Exception e) {
                ResponseUtil.serverError(resp, e.getMessage());
            }
            return;
        }

        if ("/avatar".equals(pathInfo)) {
            try {
                @SuppressWarnings("unchecked")
                Map<String, String> body = JsonUtil.readBody(req, Map.class);
                String avatarUrl = body.getOrDefault("avatarUrl", "").trim();
                if (avatarUrl.isEmpty()) {
                    ResponseUtil.badRequest(resp, "avatarUrl is required");
                    return;
                }
                Merchant updated = settingsService.updateAvatar(merchantId, avatarUrl);
                updated.setPasswordHash(null);
                ResponseUtil.ok(resp, updated);
            } catch (Exception e) {
                ResponseUtil.serverError(resp, e.getMessage());
            }
            return;
        }

        if ("/hours".equals(pathInfo)) {
            try {
                @SuppressWarnings("unchecked")
                Map<String, String> body = JsonUtil.readBody(req, Map.class);
                String hoursJson = body.getOrDefault("businessHours", "");
                if (hoursJson.isEmpty()) {
                    ResponseUtil.badRequest(resp, "businessHours is required");
                    return;
                }
                Merchant updated = settingsService.updateBusinessHours(merchantId, hoursJson);
                updated.setPasswordHash(null);
                ResponseUtil.ok(resp, updated);
            } catch (Exception e) {
                ResponseUtil.serverError(resp, e.getMessage());
            }
            return;
        }

        ResponseUtil.badRequest(resp, "Use PUT /api/settings/profile or PUT /api/settings/hours");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        String pathInfo = req.getPathInfo();      // /change-password

        if (!"/change-password".equals(pathInfo)) {
            ResponseUtil.badRequest(resp, "Use POST /api/settings/change-password");
            return;
        }

        try {
            @SuppressWarnings("unchecked")
            Map<String, String> body = JsonUtil.readBody(req, Map.class);
            String currentPassword = body.getOrDefault("currentPassword", "");
            String newPassword = body.getOrDefault("newPassword", "");

            if (currentPassword.isEmpty() || newPassword.isEmpty()) {
                ResponseUtil.badRequest(resp, "currentPassword and newPassword required");
                return;
            }
            if (newPassword.length() < 6) {
                ResponseUtil.badRequest(resp, "New password must be at least 6 characters");
                return;
            }

            boolean ok = settingsService.changePassword(merchantId, currentPassword, newPassword);
            if (ok) {
                ResponseUtil.ok(resp, "Password updated successfully");
            } else {
                ResponseUtil.unauthorized(resp, "Current password is incorrect");
            }
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }
}
