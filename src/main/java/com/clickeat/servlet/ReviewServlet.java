package com.clickeat.servlet;

import com.clickeat.service.ReviewService;
import com.clickeat.util.ResponseUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * GET /api/reviews  – paginated reviews for merchant (?page=&pageSize=)
 * No reply endpoint – dbo.Ratings has no reply column.
 */
public class ReviewServlet extends HttpServlet {

    private final ReviewService reviewService = new ReviewService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        int page     = parseIntParam(req, "page", 1);
        int pageSize = parseIntParam(req, "pageSize", 20);
        try {
            ResponseUtil.ok(resp, reviewService.getReviews(merchantId, page, pageSize));
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }

    private int parseIntParam(HttpServletRequest req, String name, int def) {
        String v = req.getParameter(name);
        if (v == null) return def;
        try { return Math.max(1, Integer.parseInt(v)); }
        catch (NumberFormatException e) { return def; }
    }
}

