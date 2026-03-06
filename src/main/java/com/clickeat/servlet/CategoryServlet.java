package com.clickeat.servlet;

import com.clickeat.model.CategoryModel;
import com.clickeat.service.MenuService;
import com.clickeat.util.JsonUtil;
import com.clickeat.util.ResponseUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;
import java.util.Map;

/**
 * GET    /api/categories       – list categories
 * POST   /api/categories       – create category   body: {name}
 * PUT    /api/categories/{id}  – update category   body: {name}
 * DELETE /api/categories/{id}  – delete category
 */
public class CategoryServlet extends HttpServlet {

    private final MenuService menuService = new MenuService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        try {
            List<CategoryModel> cats = menuService.getCategories(merchantId);
            ResponseUtil.ok(resp, cats);
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
            Map<String, String> body = JsonUtil.readBody(req, Map.class);
            String name = body.getOrDefault("name", "").trim();
            if (name.isEmpty()) {
                ResponseUtil.badRequest(resp, "name is required");
                return;
            }
            CategoryModel cat = menuService.createCategory(merchantId, name);
            ResponseUtil.created(resp, cat);
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }

    @Override
    protected void doPut(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        long catId = extractId(req);
        if (catId < 0) { ResponseUtil.badRequest(resp, "Category id required"); return; }
        try {
            @SuppressWarnings("unchecked")
            Map<String, String> body = JsonUtil.readBody(req, Map.class);
            String name = body.getOrDefault("name", "").trim();
            if (name.isEmpty()) { ResponseUtil.badRequest(resp, "name is required"); return; }
            CategoryModel cat = menuService.updateCategory(catId, merchantId, name);
            ResponseUtil.ok(resp, cat);
        } catch (IllegalArgumentException e) {
            ResponseUtil.notFound(resp, e.getMessage());
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        long catId = extractId(req);
        if (catId < 0) { ResponseUtil.badRequest(resp, "Category id required"); return; }
        try {
            boolean ok = menuService.deleteCategory(catId, merchantId);
            if (ok) ResponseUtil.ok(resp, "Deleted");
            else    ResponseUtil.notFound(resp, "Category not found");
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }

    /** Parse /api/categories/{id} → id, returns -1 on error. */
    private long extractId(HttpServletRequest req) {
        String info = req.getPathInfo();
        if (info == null || info.equals("/")) return -1;
        try { return Long.parseLong(info.substring(1)); }
        catch (NumberFormatException e) { return -1; }
    }
}

