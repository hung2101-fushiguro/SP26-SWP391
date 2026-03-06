package com.clickeat.dao;

import com.clickeat.config.DataSourceConfig;
import com.clickeat.model.MenuItem;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Maps to dbo.FoodItems joined with dbo.Categories.
 */
public class MenuItemDAO {

    private static final String SELECT_COLS
            = "fi.id, fi.category_id, c.name AS category_name, fi.merchant_user_id, "
            + "fi.name, fi.description, fi.price, fi.image_url, fi.is_available, "
            + "fi.calories, fi.protein_g, fi.carbs_g, fi.fat_g";

    public List<MenuItem> findByMerchant(long merchantUserId) throws SQLException {
        String sql = "SELECT " + SELECT_COLS
                + " FROM dbo.FoodItems fi JOIN dbo.Categories c ON c.id = fi.category_id"
                + " WHERE fi.merchant_user_id = ? ORDER BY c.sort_order, fi.name";
        List<MenuItem> list = new ArrayList<>();
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

    public Optional<MenuItem> findById(long id) throws SQLException {
        String sql = "SELECT " + SELECT_COLS
                + " FROM dbo.FoodItems fi JOIN dbo.Categories c ON c.id = fi.category_id"
                + " WHERE fi.id = ?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(map(rs));
                }
            }
        }
        return Optional.empty();
    }

    public long create(long merchantUserId, long categoryId, String name, String description,
            BigDecimal price, String imageUrl) throws SQLException {
        String sql = "INSERT INTO dbo.FoodItems "
                + "(merchant_user_id, category_id, name, description, price, image_url, is_available) "
                + "VALUES (?, ?, ?, ?, ?, ?, 1)";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, merchantUserId);
            ps.setLong(2, categoryId);
            ps.setString(3, name);
            ps.setString(4, description);
            ps.setBigDecimal(5, price);
            ps.setString(6, imageUrl);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getLong(1);
                }
            }
        }
        throw new SQLException("Failed to get generated food item id");
    }

    public boolean update(long id, long merchantUserId, long categoryId, String name,
            String description, BigDecimal price, String imageUrl,
            boolean isAvailable) throws SQLException {
        String sql = "UPDATE dbo.FoodItems "
                + "SET category_id=?, name=?, description=?, price=?, image_url=?, is_available=?, updated_at=SYSUTCDATETIME() "
                + "WHERE id=? AND merchant_user_id=?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, categoryId);
            ps.setString(2, name);
            ps.setString(3, description);
            ps.setBigDecimal(4, price);
            ps.setString(5, imageUrl);
            ps.setBoolean(6, isAvailable);
            ps.setLong(7, id);
            ps.setLong(8, merchantUserId);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean toggleAvailability(long id, long merchantUserId, boolean available) throws SQLException {
        String sql = "UPDATE dbo.FoodItems SET is_available=?, updated_at=SYSUTCDATETIME() WHERE id=? AND merchant_user_id=?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setBoolean(1, available);
            ps.setLong(2, id);
            ps.setLong(3, merchantUserId);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean delete(long id, long merchantUserId) throws SQLException {
        String sql = "DELETE FROM dbo.FoodItems WHERE id=? AND merchant_user_id=?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.setLong(2, merchantUserId);
            return ps.executeUpdate() > 0;
        }
    }

    private MenuItem map(ResultSet rs) throws SQLException {
        MenuItem mi = new MenuItem();
        mi.setId(rs.getLong("id"));
        mi.setCategoryId(rs.getLong("category_id"));
        mi.setCategoryName(rs.getString("category_name"));
        mi.setMerchantUserId(rs.getLong("merchant_user_id"));
        mi.setName(rs.getString("name"));
        mi.setDescription(rs.getString("description"));
        mi.setPrice(rs.getBigDecimal("price"));
        mi.setImageUrl(rs.getString("image_url"));
        mi.setAvailable(rs.getBoolean("is_available"));
        int cal = rs.getInt("calories");
        if (!rs.wasNull()) {
            mi.setCalories(cal);
        }
        BigDecimal p = rs.getBigDecimal("protein_g");
        if (p != null) {
            mi.setProteinG(p);
        }
        BigDecimal cb = rs.getBigDecimal("carbs_g");
        if (cb != null) {
            mi.setCarbsG(cb);
        }
        BigDecimal f = rs.getBigDecimal("fat_g");
        if (f != null) {
            mi.setFatG(f);
        }
        return mi;
    }
}
