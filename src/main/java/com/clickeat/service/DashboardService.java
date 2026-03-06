package com.clickeat.service;

import com.clickeat.dao.OrderDAO;
import com.clickeat.dao.ReviewDAO;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class DashboardService {

    private final OrderDAO orderDAO = new OrderDAO();
    private final ReviewDAO reviewDAO = new ReviewDAO();

    /**
     * Aggregated stats for the Dashboard screen. Returns: todayRevenue,
     * todayOrders, pendingOrders, avgRating, weeklyRevenue[7], weeklyOrders[7],
     * topItems[], recentOrders[]
     */
    public Map<String, Object> getStats(long merchantUserId) throws SQLException {
        OrderDAO.DashboardStats stats = orderDAO.getDashboardStats(merchantUserId);
        double avgRating = reviewDAO.averageRating(merchantUserId);

        BigDecimal[] weeklyRevenue = new BigDecimal[7];
        int[] weeklyOrders = new int[7];
        orderDAO.fillWeeklyData(merchantUserId, weeklyRevenue, weeklyOrders);

        List<Map<String, Object>> topItems = orderDAO.getTopItems(merchantUserId, 5);
        List<Map<String, Object>> recentOrders = orderDAO.getRecentOrders(merchantUserId, 10);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("todayRevenue", stats.todayRevenue);
        data.put("todayOrders", stats.todayOrders);
        data.put("pendingOrders", stats.pendingOrders);
        data.put("avgRating", Math.round(avgRating * 10.0) / 10.0);
        data.put("weeklyRevenue", weeklyRevenue);
        data.put("weeklyOrders", weeklyOrders);
        data.put("topItems", topItems);
        data.put("recentOrders", recentOrders);
        return data;
    }
}
