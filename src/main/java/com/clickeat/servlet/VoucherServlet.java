package com.clickeat.servlet;

import com.clickeat.dao.VoucherDAO;
import com.clickeat.util.ResponseUtil;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * GET /api/vouchers – list vouchers POST /api/vouchers – create voucher PATCH
 * /api/vouchers/{id}/toggle-status – toggle ACTIVE/INACTIVE PATCH
 * /api/vouchers/{id}/toggle-published – toggle is_published DELETE
 * /api/vouchers/{id} – delete voucher
 */
public class VoucherServlet extends HttpServlet {

    private final VoucherDAO dao = new VoucherDAO();
    private final ObjectMapper om = new ObjectMapper();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        try {
            ResponseUtil.ok(resp, dao.findByMerchant(merchantId));
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> body = om.readValue(req.getInputStream(), Map.class);

            String code = str(body, "code");
            String title = str(body, "title");
            String description = str(body, "description");
            String discountType = str(body, "discountType", "PERCENT");
            BigDecimal discountValue = decimal(body, "discountValue", BigDecimal.ZERO);
            BigDecimal maxDiscount = decimal(body, "maxDiscountAmount", null);
            BigDecimal minOrder = decimal(body, "minOrderAmount", null);
            String startAtStr = str(body, "startAt");
            String endAtStr = str(body, "endAt");
            Integer maxTotal = intVal(body, "maxUsesTotal");
            Integer maxPerUser = intVal(body, "maxUsesPerUser");

            if (code == null || code.isBlank()) {
                ResponseUtil.badRequest(resp, "code is required");
                return;
            }
            if (title == null || title.isBlank()) {
                ResponseUtil.badRequest(resp, "title is required");
                return;
            }

            Timestamp startAt = parseTs(startAtStr);
            Timestamp endAt = parseTs(endAtStr);
            if (startAt == null) {
                startAt = Timestamp.valueOf(LocalDateTime.now());
            }
            if (endAt == null) {
                endAt = Timestamp.valueOf(LocalDateTime.now().plusDays(30));
            }

            long newId = dao.create(merchantId, code.toUpperCase(), title, description,
                    discountType, discountValue, maxDiscount, minOrder,
                    startAt, endAt, maxTotal, maxPerUser);

            Map<String, Object> res = new LinkedHashMap<>();
            res.put("id", newId);
            ResponseUtil.ok(resp, res);
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
        long merchantId = (long) req.getAttribute("merchantId");
        String pathInfo = req.getPathInfo(); // "/{id}/toggle-status" or "/{id}/toggle-published"
        if (pathInfo == null) {
            ResponseUtil.badRequest(resp, "missing path");
            return;
        }

        String[] parts = pathInfo.split("/");
        // parts[0]="" parts[1]=id parts[2]=action
        try {
            long id = Long.parseLong(parts[1]);
            String action = parts.length > 2 ? parts[2] : "toggle-status";

            boolean ok;
            if ("toggle-published".equals(action)) {
                ok = dao.togglePublished(id, merchantId);
            } else {
                ok = dao.toggleStatus(id, merchantId);
            }
            Map<String, Object> res = new LinkedHashMap<>();
            res.put("updated", ok);
            ResponseUtil.ok(resp, res);
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        String pathInfo = req.getPathInfo();
        if (pathInfo == null) {
            ResponseUtil.badRequest(resp, "missing id");
            return;
        }
        try {
            long id = Long.parseLong(pathInfo.replaceAll("[^0-9]", ""));
            boolean ok = dao.delete(id, merchantId);
            Map<String, Object> res = new LinkedHashMap<>();
            res.put("deleted", ok);
            ResponseUtil.ok(resp, res);
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }

    // ---------- helpers ----------
    private String str(Map<String, Object> m, String key) {
        return str(m, key, null);
    }

    private String str(Map<String, Object> m, String key, String def) {
        Object v = m.get(key);
        return v != null ? v.toString() : def;
    }

    private BigDecimal decimal(Map<String, Object> m, String key, BigDecimal def) {
        Object v = m.get(key);
        if (v == null) {
            return def;
        }
        try {
            return new BigDecimal(v.toString());
        } catch (Exception e) {
            return def;
        }
    }

    private Integer intVal(Map<String, Object> m, String key) {
        Object v = m.get(key);
        if (v == null) {
            return null;
        }
        try {
            return Integer.valueOf(v.toString());
        } catch (Exception e) {
            return null;
        }
    }

    private Timestamp parseTs(String s) {
        if (s == null || s.isBlank()) {
            return null;
        }
        try {
            return Timestamp.valueOf(LocalDateTime.parse(s.replace("T", " ")
                    .replaceAll("\\..*$", ""),
                    DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        } catch (Exception e) {
            try {
                return Timestamp.valueOf(s.replace("T", " ").substring(0, 19)
                        .replace("T", " "));
            } catch (Exception ex) {
                return null;
            }
        }
    }
}
