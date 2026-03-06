package com.clickeat.dao;

import com.clickeat.config.DataSourceConfig;
import com.clickeat.model.CategoryModel;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/** Maps to dbo.Categories. */
public class CategoryDAO {

    public List<CategoryModel> findByMerchant(long merchantUserId) throws SQLException {
        String sql = "SELECT id, merchant_user_id, name, is_active, sort_order " +
                     "FROM dbo.Categories WHERE merchant_user_id = ? ORDER BY sort_order, name";
        List<CategoryModel> list = new ArrayList<>();
        try (Connection c = DataSourceConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, merchantUserId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        }
        return list;
    }

    public Optional<CategoryModel> findById(long id) throws SQLException {
        String sql = "SELECT id, merchant_user_id, name, is_active, sort_order " +
                     "FROM dbo.Categories WHERE id = ?";
        try (Connection c = DataSourceConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return Optional.of(map(rs));
            }
        }
        return Optional.empty();
    }

    public long create(long merchantUserId, String name) throws SQLException {
        String sql = "INSERT INTO dbo.Categories (merchant_user_id, name, is_active, sort_order) " +
                     "VALUES (?, ?, 1, (SELECT ISNULL(MAX(sort_order),0)+1 FROM dbo.Categories WHERE merchant_user_id=?))";
        try (Connection c = DataSourceConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong  (1, merchantUserId);
            ps.setString(2, name);
            ps.setLong  (3, merchantUserId);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getLong(1);
            }
        }
        throw new SQLException("Failed to get generated category id");
    }

    public boolean update(long id, long merchantUserId, String name) throws SQLException {
        String sql = "UPDATE dbo.Categories SET name=? WHERE id=? AND merchant_user_id=?";
        try (Connection c = DataSourceConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, name);
            ps.setLong  (2, id);
            ps.setLong  (3, merchantUserId);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean delete(long id, long merchantUserId) throws SQLException {
        String sql = "UPDATE dbo.Categories SET is_active=0 WHERE id=? AND merchant_user_id=?";
        try (Connection c = DataSourceConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.setLong(2, merchantUserId);
            return ps.executeUpdate() > 0;
        }
    }

    private CategoryModel map(ResultSet rs) throws SQLException {
        CategoryModel cat = new CategoryModel();
        cat.setId             (rs.getLong   ("id"));
        cat.setMerchantUserId (rs.getLong   ("merchant_user_id"));
        cat.setName           (rs.getString ("name"));
        cat.setActive         (rs.getBoolean("is_active"));
        cat.setSortOrder      (rs.getInt    ("sort_order"));
        return cat;
    }
}

