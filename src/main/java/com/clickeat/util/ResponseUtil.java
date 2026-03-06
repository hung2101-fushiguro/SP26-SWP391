package com.clickeat.util;

import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Standard JSON envelope helpers.
 *
 * Success → { "success": true, "data": ... } Error → { "success": false,
 * "message": "..." }
 */
public final class ResponseUtil {

    private ResponseUtil() {
    }

    public static void ok(HttpServletResponse resp, Object data) throws IOException {
        resp.setStatus(HttpServletResponse.SC_OK);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", true);
        body.put("data", data);
        JsonUtil.writeJson(resp, body);
    }

    public static void created(HttpServletResponse resp, Object data) throws IOException {
        resp.setStatus(HttpServletResponse.SC_CREATED);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", true);
        body.put("data", data);
        JsonUtil.writeJson(resp, body);
    }

    public static void error(HttpServletResponse resp, int status, String message) throws IOException {
        resp.setStatus(status);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("message", message);
        JsonUtil.writeJson(resp, body);
    }

    public static void unauthorized(HttpServletResponse resp, String message) throws IOException {
        error(resp, HttpServletResponse.SC_UNAUTHORIZED, message);
    }

    public static void forbidden(HttpServletResponse resp) throws IOException {
        error(resp, HttpServletResponse.SC_FORBIDDEN, "Access denied");
    }

    public static void notFound(HttpServletResponse resp, String message) throws IOException {
        error(resp, HttpServletResponse.SC_NOT_FOUND, message);
    }

    public static void badRequest(HttpServletResponse resp, String message) throws IOException {
        error(resp, HttpServletResponse.SC_BAD_REQUEST, message);
    }

    public static void serverError(HttpServletResponse resp, String message) throws IOException {
        error(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, message);
    }
}
