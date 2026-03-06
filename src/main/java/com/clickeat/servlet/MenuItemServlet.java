package com.clickeat.servlet;

import com.clickeat.model.MenuItem;
import com.clickeat.service.MenuService;
import com.clickeat.util.JsonUtil;
import com.clickeat.util.ResponseUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * GET   /api/menu-items                    – list all items for merchant
 * GET   /api/menu-items/{id}               – single item
 * POST  /api/menu-items                    – create item
 * PUT   /api/menu-items/{id}               – update item
 * PATCH /api/menu-items/{id}/availability  – toggle availability
 * DELETE /api/menu-items/{id}              – delete item
 */
public class MenuItemServlet extends HttpServlet {

    private final MenuService menuService = new MenuService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        String pathInfo = req.getPathInfo();
        try {
            if (pathInfo == null || pathInfo.equals("/")) {
                List<MenuItem> items = menuService.getMenuItems(merchantId);
                ResponseUtil.ok(resp, items);
            } else {
                long id = extractBaseId(req);
                if (id < 0) { ResponseUtil.badRequest(resp, "Invalid id"); return; }
                Optional<MenuItem> item = menuService.getMenuItemById(id);
                if (item.isPresent()) ResponseUtil.ok(resp, item.get());
                else                  ResponseUtil.notFound(resp, "MenuItem not found");
            }
        } catch (Exception e) { ResponseUtil.serverError(resp, e.getMessage()); }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> body = JsonUtil.readBody(req, Map.class);
            long categoryId  = toLong(body.get("categoryId"));
            String name      = str(body, "name");
            String desc      = str(body, "description");
            BigDecimal price = new BigDecimal(body.getOrDefault("price", "0").toString());
            String imageUrl  = str(body, "imageUrl");

            if (name.isEmpty() || categoryId <= 0) {
                ResponseUtil.badRequest(resp, "categoryId and name are required");
                return;
            }
            MenuItem item = menuService.createMenuItem(merchantId, categoryId, name, desc, price, imageUrl);
            ResponseUtil.created(resp, item);
        } catch (Exception e) { ResponseUtil.serverError(resp, e.getMessage()); }
    }

    @Override
    protected void doPut(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        long id = extractBaseId(req);
        if (id < 0) { ResponseUtil.badRequest(resp, "Item id required"); return; }
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> body = JsonUtil.readBody(req, Map.class);
            long categoryId  = toLong(body.get("categoryId"));
            String name      = str(body, "name");
            String desc      = str(body, "description");
            BigDecimal price = new BigDecimal(body.getOrDefault("price", "0").toString());
            String imageUrl  = str(body, "imageUrl");
            boolean available = Boolean.parseBoolean(body.getOrDefault("isAvailable", true).toString());

            MenuItem item = menuService.updateMenuItem(id, merchantId, categoryId, name, desc, price, imageUrl, available);
            ResponseUtil.ok(resp, item);
        } catch (IllegalArgumentException e) {
            ResponseUtil.notFound(resp, e.getMessage());
        } catch (Exception e) { ResponseUtil.serverError(resp, e.getMessage()); }
    }

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if ("PATCH".equalsIgnoreCase(req.getMethod())) doPatch(req, resp);
        else super.service(req, resp);
    }

    protected void doPatch(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        String path = req.getPathInfo();
        if (path != null && path.endsWith("/availability")) {
            long id = extractBaseId(req);
            if (id < 0) { ResponseUtil.badRequest(resp, "Item id required"); return; }
            try {
                @SuppressWarnings("unchecked")
                Map<String, Object> body = JsonUtil.readBody(req, Map.class);
                boolean available = Boolean.parseBoolean(body.getOrDefault("available", true).toString());
                menuService.toggleAvailability(id, merchantId, available);
                ResponseUtil.ok(resp, "Availability updated");
            } catch (Exception e) { ResponseUtil.serverError(resp, e.getMessage()); }
        } else {
            ResponseUtil.badRequest(resp, "Unknown PATCH endpoint");
        }
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        long id = extractBaseId(req);
        if (id < 0) { ResponseUtil.badRequest(resp, "Item id required"); return; }
        try {
            boolean ok = menuService.deleteMenuItem(id, merchantId);
            if (ok) ResponseUtil.ok(resp, "Deleted");
            else    ResponseUtil.notFound(resp, "MenuItem not found");
        } catch (Exception e) { ResponseUtil.serverError(resp, e.getMessage()); }
    }

    /** Parse first numeric segment of pathInfo: /5 or /5/availability → 5 */
    private long extractBaseId(HttpServletRequest req) {
        String info = req.getPathInfo();
        if (info == null || info.equals("/")) return -1;
        for (String p : info.split("/")) {
            try { return Long.parseLong(p); }
            catch (NumberFormatException ignored) {}
        }
        return -1;
    }

    private String str(Map<String, Object> m, String key) {
        Object v = m.get(key); return v == null ? "" : v.toString().trim();
    }

    private long toLong(Object o) {
        if (o == null) return 0;
        try { return Long.parseLong(o.toString()); }
        catch (NumberFormatException e) { return 0; }
    }
}

