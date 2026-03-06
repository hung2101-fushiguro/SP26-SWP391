package com.clickeat.dao;

import com.clickeat.config.DataSourceConfig;
import com.clickeat.model.OrderItemModel;
import com.clickeat.model.OrderModel;

import java.math.BigDecimal;
import java.sql.*;
import java.util.*;

/**
 * Maps to dbo.Orders + dbo.OrderItems.
 */
public class OrderDAO {

    // ------------------------------------------------------------------ find
    public List<OrderModel> findByMerchant(long merchantUserId, String status,
            int page, int pageSize) throws SQLException {
        StringBuilder sb = new StringBuilder(
                "SELECT id, order_code, merchant_user_id, receiver_name, receiver_phone,"
                + " delivery_address_line, subtotal_amount, delivery_fee, discount_amount, total_amount,"
                + " payment_method, payment_status, order_status, created_at,"
                + " accepted_at, delivered_at, cancelled_at"
                + " FROM dbo.Orders WHERE merchant_user_id = ?");
        if (status != null && !status.isBlank()) {
            sb.append(" AND order_status = ?");
        }
        sb.append(" ORDER BY created_at DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");

        List<OrderModel> list = new ArrayList<>();
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sb.toString())) {
            int idx = 1;
            ps.setLong(idx++, merchantUserId);
            if (status != null && !status.isBlank()) {
                ps.setString(idx++, status);
            }
            ps.setInt(idx++, (page - 1) * pageSize);
            ps.setInt(idx, pageSize);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapOrder(rs));
                }
            }
        }
        return list;
    }

    public int countByMerchant(long merchantUserId, String status) throws SQLException {
        StringBuilder sb = new StringBuilder(
                "SELECT COUNT(*) FROM dbo.Orders WHERE merchant_user_id = ?");
        if (status != null && !status.isBlank()) {
            sb.append(" AND order_status = ?");
        }
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sb.toString())) {
            int idx = 1;
            ps.setLong(idx++, merchantUserId);
            if (status != null && !status.isBlank()) {
                ps.setString(idx, status);
            }
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }

    public Optional<OrderModel> findById(long id) throws SQLException {
        String sql = "SELECT id, order_code, merchant_user_id, receiver_name, receiver_phone,"
                + " delivery_address_line, subtotal_amount, delivery_fee, discount_amount, total_amount,"
                + " payment_method, payment_status, order_status, created_at,"
                + " accepted_at, delivered_at, cancelled_at"
                + " FROM dbo.Orders WHERE id = ?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    OrderModel o = mapOrder(rs);
                    o.setItems(findItems(c, id));
                    return Optional.of(o);
                }
            }
        }
        return Optional.empty();
    }

    public List<OrderItemModel> findItems(Connection c, long orderId) throws SQLException {
        String sql = "SELECT id, order_id, food_item_id, item_name_snapshot,"
                + " unit_price_snapshot, quantity, note FROM dbo.OrderItems WHERE order_id = ?";
        List<OrderItemModel> items = new ArrayList<>();
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    items.add(mapItem(rs));
                }
            }
        }
        return items;
    }

    // --------------------------------------------------------------- update
    /**
     * Merchant can transition to: MERCHANT_ACCEPTED, MERCHANT_REJECTED,
     * PREPARING, READY_FOR_PICKUP.
     */
    public boolean updateStatus(long orderId, long merchantUserId, String newStatus) throws SQLException {
        String sql = "UPDATE dbo.Orders SET order_status = ? "
                + "WHERE id = ? AND merchant_user_id = ?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, newStatus);
            ps.setLong(2, orderId);
            ps.setLong(3, merchantUserId);
            return ps.executeUpdate() > 0;
        }
    }

    // -------------------------------------------------------------- mappers
    private OrderModel mapOrder(ResultSet rs) throws SQLException {
        OrderModel o = new OrderModel();
        o.setId(rs.getLong("id"));
        o.setOrderCode(rs.getString("order_code"));
        o.setMerchantUserId(rs.getLong("merchant_user_id"));
        o.setReceiverName(rs.getString("receiver_name"));
        o.setReceiverPhone(rs.getString("receiver_phone"));
        o.setDeliveryAddressLine(rs.getString("delivery_address_line"));
        o.setSubtotalAmount(rs.getBigDecimal("subtotal_amount"));
        o.setDeliveryFee(rs.getBigDecimal("delivery_fee"));
        o.setDiscountAmount(rs.getBigDecimal("discount_amount"));
        o.setTotalAmount(rs.getBigDecimal("total_amount"));
        o.setPaymentMethod(rs.getString("payment_method"));
        o.setPaymentStatus(rs.getString("payment_status"));
        o.setOrderStatus(rs.getString("order_status"));
        Timestamp ca = rs.getTimestamp("created_at");
        if (ca != null) {
            o.setCreatedAt(ca.toLocalDateTime());
        }
        Timestamp aa = rs.getTimestamp("accepted_at");
        if (aa != null) {
            o.setAcceptedAt(aa.toLocalDateTime());
        }
        Timestamp da = rs.getTimestamp("delivered_at");
        if (da != null) {
            o.setDeliveredAt(da.toLocalDateTime());
        }
        Timestamp xa = rs.getTimestamp("cancelled_at");
        if (xa != null) {
            o.setCancelledAt(xa.toLocalDateTime());
        }
        return o;
    }

    private OrderItemModel mapItem(ResultSet rs) throws SQLException {
        OrderItemModel oi = new OrderItemModel();
        oi.setId(rs.getLong("id"));
        oi.setOrderId(rs.getLong("order_id"));
        oi.setFoodItemId(rs.getLong("food_item_id"));
        oi.setItemNameSnapshot(rs.getString("item_name_snapshot"));
        oi.setUnitPriceSnapshot(rs.getBigDecimal("unit_price_snapshot"));
        oi.setQuantity(rs.getInt("quantity"));
        oi.setNote(rs.getString("note"));
        return oi;
    }

    // --------------------------------------------------------- dashboard stats
    public DashboardStats getDashboardStats(long merchantUserId) throws SQLException {
        String sql
                = "SELECT COUNT(*)                                                AS total_orders,"
                + "  ISNULL(SUM(CASE WHEN order_status='DELIVERED' THEN total_amount ELSE 0 END),0) AS total_revenue,"
                + "  ISNULL(SUM(CASE WHEN order_status='DELIVERED' AND CAST(created_at AS DATE)=CAST(GETDATE() AS DATE) THEN total_amount ELSE 0 END),0) AS today_revenue,"
                + "  COUNT(CASE WHEN order_status IN ('CREATED','PAID','MERCHANT_ACCEPTED','PREPARING','READY_FOR_PICKUP') THEN 1 END) AS pending_orders,"
                + "  COUNT(CASE WHEN order_status='DELIVERED' THEN 1 END)        AS completed_orders,"
                + "  COUNT(CASE WHEN CAST(created_at AS DATE)=CAST(GETDATE() AS DATE) THEN 1 END) AS today_orders"
                + " FROM dbo.Orders WHERE merchant_user_id = ?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, merchantUserId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    DashboardStats s = new DashboardStats();
                    s.totalOrders = rs.getInt("total_orders");
                    s.totalRevenue = rs.getBigDecimal("total_revenue");
                    s.todayRevenue = rs.getBigDecimal("today_revenue");
                    s.pendingOrders = rs.getInt("pending_orders");
                    s.completedOrders = rs.getInt("completed_orders");
                    s.todayOrders = rs.getInt("today_orders");
                    return s;
                }
            }
        }
        return new DashboardStats();
    }

    /**
     * Fills weeklyRevenue[7] and weeklyOrders[7] for the last 7 days. Index 0 =
     * 6 days ago, index 6 = today.
     */
    public void fillWeeklyData(long merchantUserId, BigDecimal[] weeklyRevenue, int[] weeklyOrders) throws SQLException {
        Arrays.fill(weeklyRevenue, BigDecimal.ZERO);
        String sql = "SELECT DATEDIFF(DAY, CAST(created_at AS DATE), CAST(GETDATE() AS DATE)) AS days_ago,"
                + " ISNULL(SUM(CASE WHEN order_status='DELIVERED' THEN total_amount ELSE 0 END), 0) AS revenue,"
                + " COUNT(*) AS cnt"
                + " FROM dbo.Orders WHERE merchant_user_id = ?"
                + " AND created_at >= DATEADD(DAY, -6, CAST(GETDATE() AS DATE))"
                + " GROUP BY DATEDIFF(DAY, CAST(created_at AS DATE), CAST(GETDATE() AS DATE))";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, merchantUserId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int daysAgo = rs.getInt("days_ago"); // 0=today, 6=oldest
                    if (daysAgo >= 0 && daysAgo <= 6) {
                        int idx = 6 - daysAgo; // 6=today, 0=oldest
                        weeklyRevenue[idx] = rs.getBigDecimal("revenue");
                        weeklyOrders[idx] = rs.getInt("cnt");
                    }
                }
            }
        }
    }

    /**
     * Top N food items by OrderItems count for this merchant.
     */
    public List<Map<String, Object>> getTopItems(long merchantUserId, int limit) throws SQLException {
        String sql = "SELECT TOP " + limit + " fi.name, COUNT(*) AS cnt"
                + " FROM dbo.OrderItems oi"
                + " JOIN dbo.FoodItems fi ON fi.id = oi.food_item_id"
                + " JOIN dbo.Orders o ON o.id = oi.order_id"
                + " WHERE o.merchant_user_id = ?"
                + " GROUP BY fi.id, fi.name"
                + " ORDER BY cnt DESC";
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, merchantUserId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("name", rs.getString("name"));
                    item.put("orders", rs.getInt("cnt"));
                    list.add(item);
                }
            }
        }
        return list;
    }

    /**
     * Most recent N orders for dashboard display.
     */
    public List<Map<String, Object>> getRecentOrders(long merchantUserId, int limit) throws SQLException {
        String sql = "SELECT TOP " + limit + " id, order_code, receiver_name, total_amount, order_status, created_at"
                + " FROM dbo.Orders WHERE merchant_user_id = ?"
                + " ORDER BY created_at DESC";
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, merchantUserId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> order = new LinkedHashMap<>();
                    order.put("id", rs.getLong("id"));
                    order.put("orderCode", rs.getString("order_code"));
                    order.put("customerName", rs.getString("receiver_name"));
                    order.put("total", rs.getBigDecimal("total_amount"));
                    order.put("status", rs.getString("order_status"));
                    Timestamp ts = rs.getTimestamp("created_at");
                    order.put("createdAt", ts != null ? ts.toLocalDateTime().toString() : null);
                    list.add(order);
                }
            }
        }
        return list;
    }

    public static class DashboardStats {

        public int totalOrders;
        public BigDecimal totalRevenue = BigDecimal.ZERO;
        public BigDecimal todayRevenue = BigDecimal.ZERO;
        public int pendingOrders;
        public int completedOrders;
        public int todayOrders;
    }
}
