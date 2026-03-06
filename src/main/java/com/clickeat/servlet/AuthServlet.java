package com.clickeat.servlet;

import com.clickeat.service.AuthService;
import com.clickeat.util.JsonUtil;
import com.clickeat.util.ResponseUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * POST /api/auth/login â€“ { email, password } POST /api/auth/register â€“ {
 * name, email, password, phone, address }
 */
public class AuthServlet extends HttpServlet {

    private final AuthService authService = new AuthService();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String servletPath = req.getServletPath();
        String pathInfo = req.getPathInfo();
        String path = (pathInfo != null) ? servletPath + pathInfo : servletPath;

        try {
            @SuppressWarnings("unchecked")
            Map<String, String> body = JsonUtil.readBody(req, Map.class);

            if ("/api/auth/login".equals(path)) {
                handleLogin(body, resp);
            } else if ("/api/auth/register".equals(path)) {
                handleRegister(body, resp);
            } else if ("/api/auth/google".equals(path)) {
                handleGoogleLogin(body, resp);
            } else if ("/api/auth/forgot-password".equals(path)) {
                handleForgotPassword(body, resp);
            } else if ("/api/auth/reset-password".equals(path)) {
                handleResetPassword(body, resp);
            }

        } catch (SQLException e) {
            System.err.println("[AuthServlet] SQL error: " + e.getMessage());
            ResponseUtil.serverError(resp, "Database error: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("[AuthServlet] Unexpected error: " + e.getClass().getSimpleName() + ": " + e.getMessage());
            ResponseUtil.serverError(resp, "Server error: " + e.getMessage());
        }
    }

    private void handleGoogleLogin(Map<String, String> body, HttpServletResponse resp) throws Exception {
        String credential = body.getOrDefault("credential", "").trim();
        if (credential.isEmpty()) {
            ResponseUtil.badRequest(resp, "credential is required");
            return;
        }
        Map<String, Object> result = authService.googleLogin(credential);
        if (result == null) {
            ResponseUtil.unauthorized(resp, "Tài khoản không tồn tại hoặc chưa được phê duyệt");
            return;
        }
        if (Boolean.TRUE.equals(result.get("notRegistered"))) {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            Map<String, Object> notRegBody = new LinkedHashMap<>();
            notRegBody.put("success", false);
            notRegBody.put("notRegistered", true);
            notRegBody.put("email", result.get("email"));
            notRegBody.put("name", result.get("name"));
            JsonUtil.writeJson(resp, notRegBody);
            return;
        }
        ResponseUtil.ok(resp, result);
    }

    private void handleForgotPassword(Map<String, String> body, HttpServletResponse resp) throws Exception {
        String phone = body.getOrDefault("phone", "").trim();
        if (phone.isEmpty()) {
            ResponseUtil.badRequest(resp, "phone is required");
            return;
        }
        boolean sent = authService.forgotPassword(phone);
        if (!sent) {
            // Generic message – don't reveal whether phone exists
            ResponseUtil.ok(resp, Map.of("message", "Nếu số điện thoại hợp lệ, OTP đã được gửi."));
            return;
        }
        ResponseUtil.ok(resp, Map.of("message", "OTP đã được gửi đến số " + phone));
    }

    private void handleResetPassword(Map<String, String> body, HttpServletResponse resp) throws Exception {
        String phone = body.getOrDefault("phone", "").trim();
        String otp = body.getOrDefault("otp", "").trim();
        String newPassword = body.getOrDefault("newPassword", "");
        if (phone.isEmpty() || otp.isEmpty() || newPassword.isEmpty()) {
            ResponseUtil.badRequest(resp, "phone, otp and newPassword are required");
            return;
        }
        if (newPassword.length() < 6) {
            ResponseUtil.badRequest(resp, "Mật khẩu phải ít nhất 6 ký tự");
            return;
        }
        boolean ok = authService.resetPassword(phone, otp, newPassword);
        if (!ok) {
            ResponseUtil.error(resp, 422, "OTP không hợp lệ hoặc đã hết hạn");
            return;
        }
        ResponseUtil.ok(resp, Map.of("message", "Mật khẩu đã được cập nhật thành công"));
    }

    private void handleLogin(Map<String, String> body, HttpServletResponse resp) throws Exception {
        String email = body.getOrDefault("email", "").trim();
        String password = body.getOrDefault("password", "");

        if (email.isEmpty() || password.isEmpty()) {
            ResponseUtil.badRequest(resp, "Email and password are required");
            return;
        }

        Map<String, Object> result = authService.login(email, password);
        if (result == null) {
            ResponseUtil.unauthorized(resp, "Invalid email or password");
            return;
        }
        ResponseUtil.ok(resp, result);
    }

    private void handleRegister(Map<String, String> body, HttpServletResponse resp) throws Exception {
        String fullName = body.getOrDefault("fullName", "").trim();
        String email = body.getOrDefault("email", "").trim();
        String password = body.getOrDefault("password", "");
        String phone = body.getOrDefault("phone", "");
        String shopName = body.getOrDefault("shopName", fullName).trim();
        String shopPhone = body.getOrDefault("shopPhone", phone);
        String shopAddressLine = body.getOrDefault("shopAddressLine", "");

        if (fullName.isEmpty() || email.isEmpty() || password.isEmpty()) {
            ResponseUtil.badRequest(resp, "fullName, email and password are required");
            return;
        }
        if (password.length() < 6) {
            ResponseUtil.badRequest(resp, "Password must be at least 6 characters");
            return;
        }

        Map<String, Object> result = authService.register(fullName, email, password,
                phone, shopName, shopPhone, shopAddressLine);
        if (result == null) {
            ResponseUtil.error(resp, HttpServletResponse.SC_CONFLICT, "Email already registered");
            return;
        }
        ResponseUtil.created(resp, result);
    }
}
