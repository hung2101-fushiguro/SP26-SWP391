package com.clickeat.servlet;

import com.clickeat.dao.AnalyticsDAO;
import com.clickeat.util.ResponseUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.*;

/**
 * GET /api/analytics?period=7|30|365 Returns: summary KPIs, daily revenue
 * array, status breakdown, top items.
 */
public class AnalyticsServlet extends HttpServlet {

    private final AnalyticsDAO dao = new AnalyticsDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        long merchantId = (long) req.getAttribute("merchantId");
        int period = parseIntParam(req, "period", 7);
        // Clamp to valid values
        if (period != 7 && period != 30 && period != 365) {
            period = 7;
        }

        try {
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("period", period);
            result.put("summary", dao.getSummary(merchantId, period));
            result.put("dailyRevenue", dao.getDailyRevenue(merchantId, period));
            result.put("statusBreakdown", dao.getStatusBreakdown(merchantId, period));
            result.put("topItems", dao.getTopItems(merchantId, period, 10));
            ResponseUtil.ok(resp, result);
        } catch (Exception e) {
            ResponseUtil.serverError(resp, e.getMessage());
        }
    }

    private int parseIntParam(HttpServletRequest req, String name, int def) {
        String v = req.getParameter(name);
        if (v == null) {
            return def;
        }
        try {
            return Integer.parseInt(v);
        } catch (NumberFormatException e) {
            return def;
        }
    }
}
