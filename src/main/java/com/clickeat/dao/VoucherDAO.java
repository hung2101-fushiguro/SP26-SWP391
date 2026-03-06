package com.clickeat.dao;

import com.clickeat.config.DataSourceConfig;

import java.math.BigDecimal;
import java.sql.*;
import java.util.*;

public class VoucherDAO {

    private static final String SELECT_COLS
            = "v.id, v.code, v.title, v.description, v.discount_type, v.discount_value,"
            + " v.max_discount_amount, v.min_order_amount, v.start_at, v.end_at,"
            + " v.max_uses_total, v.max_uses_per_user, v.is_published, v.status, v.created_at,"
            + " (SELECT COUNT(*) FROM dbo.VoucherUsages vu WHERE vu.voucher_id = v.id) AS used_count";

    public List<Map<String, Object>> findByMerchant(long merchantUserId) throws SQLException {
        String sql = "SELECT " + SELECT_COLS
                + " FROM dbo.Vouchers v WHERE v.merchant_user_id = ?"
                + " ORDER BY v.created_at DESC";
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, merchantUserId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(map(rs));
                }
            }
        }
        return list;
    }

    /**
     * Create a new voucher. Returns the new id.
     */
    public long create(long merchantUserId, String code, String title, String description,
            String discountType, BigDecimal discountValue, BigDecimal maxDiscount,
            BigDecimal minOrder, Timestamp startAt, Timestamp endAt,
            Integer maxUsesTotal, Integer maxUsesPerUser) throws SQLException {
        String sql = "INSERT INTO dbo.Vouchers"
                + "(merchant_user_id,code,title,description,discount_type,discount_value,"
                + "max_discount_amount,min_order_amount,start_at,end_at,max_uses_total,max_uses_per_user)"
                + " VALUES(?,?,?,?,?,?,?,?,?,?,?,?)";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, merchantUserId);
            ps.setString(2, code);
            ps.setString(3, title);
            ps.setString(4, description);
            ps.setString(5, discountType);
            ps.setBigDecimal(6, discountValue);
            if (maxDiscount != null) {
                ps.setBigDecimal(7, maxDiscount);
            } else {
                ps.setNull(7, Types.DECIMAL);
            }
            if (minOrder != null) {
                ps.setBigDecimal(8, minOrder); 
            }else {
                ps.setNull(8, Types.DECIMAL);
            }
            ps.setTimestamp(9, startAt);
            ps.setTimestamp(10, endAt);
            if (maxUsesTotal != null) {
                ps.setInt(11, maxUsesTotal); 
            }else {
                ps.setNull(11, Types.INTEGER);
            }
            if (maxUsesPerUser != null) {
                ps.setInt(12, maxUsesPerUser);
            } else {
                ps.setNull(12, Types.INTEGER);
            }
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getLong(1);
                }
            }
        }
        return -1;
    }

    /**
     * Toggle ACTIVE / INACTIVE for a voucher belonging to this merchant.
     */
    public boolean toggleStatus(long voucherId, long merchantUserId) throws SQLException {
        String sql = "UPDATE dbo.Vouchers"
                + " SET status = CASE WHEN status='ACTIVE' THEN 'INACTIVE' ELSE 'ACTIVE' END,"
                + "     updated_at = GETDATE()"
                + " WHERE id = ? AND merchant_user_id = ?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, voucherId);
            ps.setLong(2, merchantUserId);
            return ps.executeUpdate() > 0;
        }
    }

    /**
     * Toggle is_published for a voucher.
     */
    public boolean togglePublished(long voucherId, long merchantUserId) throws SQLException {
        String sql = "UPDATE dbo.Vouchers"
                + " SET is_published = CASE WHEN is_published=1 THEN 0 ELSE 1 END,"
                + "     updated_at = GETDATE()"
                + " WHERE id = ? AND merchant_user_id = ?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, voucherId);
            ps.setLong(2, merchantUserId);
            return ps.executeUpdate() > 0;
        }
    }

    /**
     * Delete a voucher belonging to this merchant.
     */
    public boolean delete(long voucherId, long merchantUserId) throws SQLException {
        String sql = "DELETE FROM dbo.Vouchers WHERE id = ? AND merchant_user_id = ?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, voucherId);
            ps.setLong(2, merchantUserId);
            return ps.executeUpdate() > 0;
        }
    }

    private Map<String, Object> map(ResultSet rs) throws SQLException {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", rs.getLong("id"));
        m.put("code", rs.getString("code"));
        m.put("title", rs.getString("title"));
        m.put("description", rs.getString("description"));
        m.put("discountType", rs.getString("discount_type"));
        m.put("discountValue", rs.getBigDecimal("discount_value"));
        m.put("maxDiscountAmount", rs.getBigDecimal("max_discount_amount"));
        m.put("minOrderAmount", rs.getBigDecimal("min_order_amount"));
        Timestamp sa = rs.getTimestamp("start_at");
        Timestamp ea = rs.getTimestamp("end_at");
        m.put("startAt", sa != null ? sa.toString() : null);
        m.put("endAt", ea != null ? ea.toString() : null);
        m.put("maxUsesTotal", rs.getObject("max_uses_total"));
        m.put("maxUsesPerUser", rs.getObject("max_uses_per_user"));
        m.put("isPublished", rs.getBoolean("is_published"));
        m.put("status", rs.getString("status"));
        m.put("usedCount", rs.getInt("used_count"));
        Timestamp ca = rs.getTimestamp("created_at");
        m.put("createdAt", ca != null ? ca.toString() : null);
        return m;
    }
}
