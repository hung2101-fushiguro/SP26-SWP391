package com.clickeat.servlet;

import com.clickeat.model.OrderModel;
import com.clickeat.service.OrderService;
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
 * GET /api/orders – paginated list (?status=&page=&pageSize=) GET
 * /api/orders/{id} – single order with items PATCH /api/orders/{id}/status –
 * update status body: { "status": "MERCHANT_ACCEPTED" }
 */
public class OrderServlet extends HttpServlet {

    private final OrderService orderService = new OrderService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        String pathInfo = req.getPathInfo();   // null or "/{id}"

        try {
            if (pathInfo == null || pathInfo.equals("/")) {
                String status = req.getParameter("status");
                int page = parseIntParam(req, "page", 1);
                int pageSize = parseIntParam(req, "pageSize", 20);
                ResponseUtil.ok(resp, orderService.getOrders(merchantId, status, page, pageSize));
            } else {
                long orderId = extractId(pathInfo);
                if (orderId < 0) {
                    ResponseUtil.badRequest(resp, "Invalid order id");
                    return;
                }
                Optional<OrderModel> order = orderService.getOrderById(orderId);
                if (order.isPresent()) {
                    if (order.get().getMerchantUserId() != merchantId) {
                        ResponseUtil.forbidden(resp);
                        return;
                    }
                    ResponseUtil.ok(resp, order.get());
                } else {
                    ResponseUtil.notFound(resp, "Order not found");
                }
            }
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if ("PATCH".equalsIgnoreCase(req.getMethod())) {
            doPatch(req, resp); 
        }else {
            super.service(req, resp);
        }
    }

    /**
     * PATCH /api/orders/{id}/status
     */
    protected void doPatch(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        String pathInfo = req.getPathInfo();   // e.g. /123/status

        if (pathInfo == null || !pathInfo.endsWith("/status")) {
            ResponseUtil.badRequest(resp, "Use PATCH /api/orders/{id}/status");
            return;
        }

        long orderId = extractId(pathInfo.substring(0, pathInfo.lastIndexOf("/status")));
        if (orderId < 0) {
            ResponseUtil.badRequest(resp, "Invalid order id");
            return;
        }

        try {
            @SuppressWarnings("unchecked")
            Map<String, String> body = JsonUtil.readBody(req, Map.class);
            String newStatus = body.getOrDefault("status", "").trim();
            if (newStatus.isEmpty()) {
                ResponseUtil.badRequest(resp, "status is required");
                return;
            }

            boolean ok = orderService.updateStatus(orderId, merchantId, newStatus);
            if (ok) {
                ResponseUtil.ok(resp, "Order status updated to " + newStatus.toUpperCase()); 
            }else {
                ResponseUtil.notFound(resp, "Order not found or not yours");
            }
        } catch (IllegalArgumentException e) {
            ResponseUtil.badRequest(resp, e.getMessage());
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }

    /**
     * Parse first numeric segment: "/123" or "/123/status" → 123
     */
    private long extractId(String pathInfo) {
        if (pathInfo == null) {
            return -1;
        }
        String[] parts = pathInfo.split("/");
        for (String p : parts) {
            try {
                return Long.parseLong(p);
            } catch (NumberFormatException ignored) {
            }
        }
        return -1;
    }

    private int parseIntParam(HttpServletRequest req, String name, int def) {
        String v = req.getParameter(name);
        if (v == null) {
            return def;
        }
        try {
            return Math.max(1, Integer.parseInt(v));
        } catch (NumberFormatException e) {
            return def;
        }
    }
}
