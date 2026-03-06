package com.clickeat.dao;

import com.clickeat.config.DataSourceConfig;
import com.clickeat.model.ReviewModel;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Maps to dbo.Ratings WHERE target_type = 'MERCHANT'. No reply column in
 * schema.
 */
public class ReviewDAO {

    private static final String SELECT_COLS
            = "r.id, r.order_id, r.target_user_id, r.stars, r.comment, r.created_at,"
            + " u.full_name AS rater_name";

    public List<ReviewModel> findByMerchant(long merchantUserId, int page, int pageSize) throws SQLException {
        String sql = "SELECT " + SELECT_COLS
                + " FROM dbo.Ratings r"
                + " LEFT JOIN dbo.Users u ON u.id = r.rater_customer_id"
                + " WHERE r.target_type = 'MERCHANT' AND r.target_user_id = ?"
                + " ORDER BY r.created_at DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";
        List<ReviewModel> list = new ArrayList<>();
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, merchantUserId);
            ps.setInt(2, (page - 1) * pageSize);
            ps.setInt(3, pageSize);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(map(rs));
                }
            }
        }
        return list;
    }

    public int countByMerchant(long merchantUserId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM dbo.Ratings"
                + " WHERE target_type = 'MERCHANT' AND target_user_id = ?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, merchantUserId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }

    public double averageRating(long merchantUserId) throws SQLException {
        String sql = "SELECT AVG(CAST(stars AS FLOAT)) FROM dbo.Ratings"
                + " WHERE target_type = 'MERCHANT' AND target_user_id = ?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, merchantUserId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getDouble(1);
                }
            }
        }
        return 0.0;
    }

    public Optional<ReviewModel> findById(long id) throws SQLException {
        String sql = "SELECT " + SELECT_COLS
                + " FROM dbo.Ratings r"
                + " LEFT JOIN dbo.Users u ON u.id = r.rater_customer_id"
                + " WHERE r.id = ?";
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

    private ReviewModel map(ResultSet rs) throws SQLException {
        ReviewModel r = new ReviewModel();
        r.setId(rs.getLong("id"));
        r.setOrderId(rs.getLong("order_id"));
        r.setTargetUserId(rs.getLong("target_user_id"));
        r.setRaterName(rs.getString("rater_name"));
        r.setStars(rs.getInt("stars"));
        r.setComment(rs.getString("comment"));
        Timestamp ca = rs.getTimestamp("created_at");
        if (ca != null) {
            r.setCreatedAt(ca.toLocalDateTime());
        }
        return r;
    }
}
