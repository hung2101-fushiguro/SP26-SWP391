package com.clickeat.servlet;

import com.clickeat.dao.NotificationDAO;
import com.clickeat.util.ResponseUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.*;

/**
 * GET /api/notifications – list + unread count PATCH
 * /api/notifications/read-all – mark all read PATCH /api/notifications/{id} –
 * mark one read
 */
public class NotificationServlet extends HttpServlet {

    private final NotificationDAO dao = new NotificationDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long userId = (long) req.getAttribute("merchantId");
        try {
            List<Map<String, Object>> items = dao.findByUser(userId);
            int unread = dao.countUnread(userId);
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("unread", unread);
            result.put("items", items);
            ResponseUtil.ok(resp, result);
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if ("PATCH".equalsIgnoreCase(req.getMethod())) {
            doPatch(req, resp);
        } else {
            super.service(req, resp);
        }
    }

    protected void doPatch(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long userId = (long) req.getAttribute("merchantId");
        String pathInfo = req.getPathInfo(); // null or "/read-all" or "/{id}"

        try {
            if (pathInfo == null || pathInfo.equals("/read-all")) {
                int updated = dao.markAllRead(userId);
                Map<String, Object> result = new LinkedHashMap<>();
                result.put("updated", updated);
                ResponseUtil.ok(resp, result);
            } else {
                // PATCH /api/notifications/{id}
                String[] parts = pathInfo.split("/");
                long id = Long.parseLong(parts[parts.length - 1]);
                boolean ok = dao.markRead(id, userId);
                Map<String, Object> result = new LinkedHashMap<>();
                result.put("success", ok);
                ResponseUtil.ok(resp, result);
            }
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }
}
