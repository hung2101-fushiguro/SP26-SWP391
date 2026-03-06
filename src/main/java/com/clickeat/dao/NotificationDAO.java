package com.clickeat.dao;

import com.clickeat.config.DataSourceConfig;

import java.sql.*;
import java.util.*;

public class NotificationDAO {

    /**
     * All notifications for a user (most recent 50).
     */
    public List<Map<String, Object>> findByUser(long userId) throws SQLException {
        String sql = "SELECT TOP 50 id, type, content, is_read, created_at"
                + " FROM dbo.Notifications WHERE user_id = ?"
                + " ORDER BY created_at DESC";
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("id", rs.getLong("id"));
                    m.put("type", rs.getString("type"));
                    m.put("content", rs.getString("content"));
                    m.put("isRead", rs.getBoolean("is_read"));
                    Timestamp ca = rs.getTimestamp("created_at");
                    m.put("createdAt", ca != null ? ca.toString() : null);
                    list.add(m);
                }
            }
        }
        return list;
    }

    /**
     * Count unread notifications for a user.
     */
    public int countUnread(long userId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM dbo.Notifications WHERE user_id = ? AND is_read = 0";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }

    /**
     * Mark a single notification as read.
     */
    public boolean markRead(long notificationId, long userId) throws SQLException {
        String sql = "UPDATE dbo.Notifications SET is_read = 1"
                + " WHERE id = ? AND user_id = ?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, notificationId);
            ps.setLong(2, userId);
            return ps.executeUpdate() > 0;
        }
    }

    /**
     * Mark ALL notifications as read for a user.
     */
    public int markAllRead(long userId) throws SQLException {
        String sql = "UPDATE dbo.Notifications SET is_read = 1"
                + " WHERE user_id = ? AND is_read = 0";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, userId);
            return ps.executeUpdate();
        }
    }

    /**
     * Insert a new notification (used internally by other services).
     */
    public void insert(long userId, String type, String content) throws SQLException {
        String sql = "INSERT INTO dbo.Notifications(user_id, type, content)"
                + " VALUES(?, ?, ?)";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.setString(2, type);
            ps.setString(3, content);
            ps.executeUpdate();
        }
    }
}
