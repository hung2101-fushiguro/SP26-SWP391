package com.clickeat.dao;

import com.clickeat.config.DataSourceConfig;

import java.math.BigDecimal;
import java.sql.*;
import java.util.*;

public class AnalyticsDAO {

    /**
     * Daily revenue/order aggregate for last N days.
     */
    public List<Map<String, Object>> getDailyRevenue(long merchantId, int days) throws SQLException {
        String sql = "SELECT CAST(created_at AS DATE) AS day,"
                + " COUNT(*) AS orders,"
                + " SUM(total_amount) AS revenue"
                + " FROM dbo.Orders"
                + " WHERE merchant_user_id = ?"
                + "   AND order_status IN ('DELIVERED','READY_FOR_PICKUP','PICKED_UP','DELIVERING')"
                + "   AND created_at >= DATEADD(DAY, ?, CAST(GETDATE() AS DATE))"
                + " GROUP BY CAST(created_at AS DATE)"
                + " ORDER BY CAST(created_at AS DATE) ASC";
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, merchantId);
            ps.setInt(2, -(days - 1));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("day", rs.getString("day"));
                    m.put("orders", rs.getInt("orders"));
                    m.put("revenue", rs.getBigDecimal("revenue"));
                    list.add(m);
                }
            }
        }
        return list;
    }

    /**
     * Order count by status for last N days.
     */
    public Map<String, Integer> getStatusBreakdown(long merchantId, int days) throws SQLException {
        String sql = "SELECT order_status, COUNT(*) AS cnt"
                + " FROM dbo.Orders"
                + " WHERE merchant_user_id = ?"
                + "   AND created_at >= DATEADD(DAY, ?, CAST(GETDATE() AS DATE))"
                + " GROUP BY order_status";
        Map<String, Integer> map = new LinkedHashMap<>();
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, merchantId);
            ps.setInt(2, -(days - 1));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    map.put(rs.getString("order_status"), rs.getInt("cnt"));
                }
            }
        }
        return map;
    }

    /**
     * Top food items by sold quantity for last N days.
     */
    public List<Map<String, Object>> getTopItems(long merchantId, int days, int limit) throws SQLException {
        String sql = "SELECT TOP (?) fi.name, SUM(oi.quantity) AS qty,"
                + " SUM(oi.quantity * oi.unit_price_snapshot) AS revenue"
                + " FROM dbo.OrderItems oi"
                + " JOIN dbo.FoodItems fi ON fi.id = oi.food_item_id"
                + " JOIN dbo.Orders o ON o.id = oi.order_id"
                + " WHERE o.merchant_user_id = ?"
                + "   AND o.created_at >= DATEADD(DAY, ?, CAST(GETDATE() AS DATE))"
                + " GROUP BY fi.name"
                + " ORDER BY qty DESC";
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ps.setLong(2, merchantId);
            ps.setInt(3, -(days - 1));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("name", rs.getString("name"));
                    m.put("qty", rs.getInt("qty"));
                    m.put("revenue", rs.getBigDecimal("revenue"));
                    list.add(m);
                }
            }
        }
        return list;
    }

    /**
     * Summary KPIs for a period.
     */
    public Map<String, Object> getSummary(long merchantId, int days) throws SQLException {
        String sql = "SELECT"
                + " COUNT(*) AS total_orders,"
                + " SUM(CASE WHEN order_status='DELIVERED' THEN total_amount ELSE 0 END) AS total_revenue,"
                + " AVG(CASE WHEN order_status='DELIVERED' THEN total_amount ELSE NULL END) AS avg_order_value,"
                + " SUM(CASE WHEN order_status IN ('CANCELLED','MERCHANT_REJECTED','FAILED') THEN 1 ELSE 0 END) AS cancelled_orders"
                + " FROM dbo.Orders"
                + " WHERE merchant_user_id = ?"
                + "   AND created_at >= DATEADD(DAY, ?, CAST(GETDATE() AS DATE))";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, merchantId);
            ps.setInt(2, -(days - 1));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("totalOrders", rs.getInt("total_orders"));
                    BigDecimal rev = rs.getBigDecimal("total_revenue");
                    m.put("totalRevenue", rev != null ? rev : BigDecimal.ZERO);
                    BigDecimal avg = rs.getBigDecimal("avg_order_value");
                    m.put("avgOrderValue", avg != null ? avg : BigDecimal.ZERO);
                    m.put("cancelledOrders", rs.getInt("cancelled_orders"));
                    return m;
                }
            }
        }
        Map<String, Object> empty = new LinkedHashMap<>();
        empty.put("totalOrders", 0);
        empty.put("totalRevenue", BigDecimal.ZERO);
        empty.put("avgOrderValue", BigDecimal.ZERO);
        empty.put("cancelledOrders", 0);
        return empty;
    }

    /**
     * Wallet: total delivered revenue, this month, pending (not yet delivered).
     */
    public Map<String, Object> getWalletStats(long merchantId) throws SQLException {
        String sql = "SELECT"
                + " SUM(CASE WHEN order_status='DELIVERED' THEN total_amount ELSE 0 END) AS total_revenue,"
                + " SUM(CASE WHEN order_status='DELIVERED'"
                + "          AND YEAR(created_at)=YEAR(GETDATE()) AND MONTH(created_at)=MONTH(GETDATE())"
                + "          THEN total_amount ELSE 0 END) AS month_revenue,"
                + " SUM(CASE WHEN order_status IN ('MERCHANT_ACCEPTED','PREPARING','READY_FOR_PICKUP','PICKED_UP','DELIVERING')"
                + "          THEN total_amount ELSE 0 END) AS pending_revenue,"
                + " COUNT(CASE WHEN order_status='DELIVERED' THEN 1 END) AS delivered_count"
                + " FROM dbo.Orders WHERE merchant_user_id = ?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, merchantId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    BigDecimal total = rs.getBigDecimal("total_revenue");
                    BigDecimal month = rs.getBigDecimal("month_revenue");
                    BigDecimal pending = rs.getBigDecimal("pending_revenue");
                    // 90% of total revenue is "available" (simulating platform fee of 10%)
                    BigDecimal available = total != null
                            ? total.multiply(new BigDecimal("0.90")).setScale(0, java.math.RoundingMode.DOWN)
                            : BigDecimal.ZERO;
                    m.put("availableBalance", available);
                    m.put("totalRevenue", total != null ? total : BigDecimal.ZERO);
                    m.put("monthRevenue", month != null ? month : BigDecimal.ZERO);
                    m.put("pendingRevenue", pending != null ? pending : BigDecimal.ZERO);
                    m.put("deliveredCount", rs.getInt("delivered_count"));
                    return m;
                }
            }
        }
        Map<String, Object> empty = new LinkedHashMap<>();
        empty.put("availableBalance", BigDecimal.ZERO);
        empty.put("totalRevenue", BigDecimal.ZERO);
        empty.put("monthRevenue", BigDecimal.ZERO);
        empty.put("pendingRevenue", BigDecimal.ZERO);
        empty.put("deliveredCount", 0);
        return empty;
    }

    /* ──────────────────────────────────────────────────────────────────
     * Withdrawal requests
     * ────────────────────────────────────────────────────────────────── */

    /**
     * Create a new withdrawal request for the merchant.
     */
    public long createWithdrawal(long merchantId, java.math.BigDecimal amount,
            String bankName, String bankAccount, String accountHolder) throws SQLException {
        String sql = "INSERT INTO dbo.WithdrawalRequests"
                + " (merchant_user_id, amount, bank_name, bank_account, account_holder, status)"
                + " OUTPUT INSERTED.id"
                + " VALUES (?, ?, ?, ?, ?, 'PENDING')";
        try (Connection c = DataSourceConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, merchantId);
            ps.setBigDecimal(2, amount);
            ps.setString(3, bankName);
            ps.setString(4, bankAccount);
            ps.setString(5, accountHolder);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getLong(1);
            }
        }
        return -1L;
    }

    /**
     * List withdrawal requests for a merchant (newest first).
     */
    public List<Map<String, Object>> getWithdrawals(long merchantId, int limit) throws SQLException {
        String sql = "SELECT TOP (?) id, amount, bank_name, bank_account, account_holder,"
                + " status, note, created_at, processed_at"
                + " FROM dbo.WithdrawalRequests"
                + " WHERE merchant_user_id = ?"
                + " ORDER BY created_at DESC";
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection c = DataSourceConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ps.setLong(2, merchantId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("id", rs.getLong("id"));
                    m.put("amount", rs.getBigDecimal("amount"));
                    m.put("bankName", rs.getString("bank_name"));
                    m.put("bankAccount", rs.getString("bank_account"));
                    m.put("accountHolder", rs.getString("account_holder"));
                    m.put("status", rs.getString("status"));
                    m.put("note", rs.getString("note"));
                    Timestamp ca = rs.getTimestamp("created_at");
                    m.put("createdAt", ca != null ? ca.toString() : null);
                    Timestamp pa = rs.getTimestamp("processed_at");
                    m.put("processedAt", pa != null ? pa.toString() : null);
                    list.add(m);
                }
            }
        }
        return list;
    }

    /**
     * Recent completed orders as wallet transactions.
     */
    public List<Map<String, Object>> getWalletTransactions(long merchantId, int limit) throws SQLException {
        String sql = "SELECT TOP (?) o.order_code, o.total_amount, o.order_status, o.created_at,"
                + " o.delivered_at"
                + " FROM dbo.Orders o"
                + " WHERE o.merchant_user_id = ?"
                + "   AND o.order_status IN ('DELIVERED','CANCELLED','FAILED','REFUNDED')"
                + " ORDER BY o.created_at DESC";
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ps.setLong(2, merchantId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("orderCode", rs.getString("order_code"));
                    m.put("amount", rs.getBigDecimal("total_amount"));
                    m.put("status", rs.getString("order_status"));
                    Timestamp ca = rs.getTimestamp("created_at");
                    m.put("date", ca != null ? ca.toString() : null);
                    list.add(m);
                }
            }
        }
        return list;
    }
}
