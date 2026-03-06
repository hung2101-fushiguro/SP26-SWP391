package com.clickeat.servlet;

import com.clickeat.service.DashboardService;
import com.clickeat.util.ResponseUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.Map;

/**
 * GET /api/dashboard/stats Registered via web.xml at /api/dashboard/*
 */
public class DashboardServlet extends HttpServlet {

    private final DashboardService dashboardService = new DashboardService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        try {
            Map<String, Object> stats = dashboardService.getStats(merchantId);
            ResponseUtil.ok(resp, stats);
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }
}
