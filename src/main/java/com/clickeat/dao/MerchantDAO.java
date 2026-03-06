package com.clickeat.dao;

import com.clickeat.config.DataSourceConfig;
import com.clickeat.model.Merchant;
import org.mindrot.jbcrypt.BCrypt;

import java.sql.*;
import java.util.Optional;

/**
 * DAO for dbo.Users (role='MERCHANT') joined with dbo.MerchantProfiles.
 */
public class MerchantDAO {

    private static final String BASE_SELECT
            = "SELECT u.id AS user_id, u.full_name, u.email, u.phone, u.password_hash, "
            + "u.status AS user_status, mp.shop_name, mp.shop_phone, mp.shop_address_line, "
            + "mp.province_name, mp.district_name, mp.ward_name, mp.status AS shop_status, "
            + "mp.business_hours, mp.avatar_url, u.created_at "
            + "FROM dbo.Users u JOIN dbo.MerchantProfiles mp ON mp.user_id = u.id "
            + "WHERE u.role = 'MERCHANT'";

    public Optional<Merchant> findByEmail(String email) throws SQLException {
        String sql = BASE_SELECT + " AND u.email = ?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(map(rs));
                }
            }
        }
        return Optional.empty();
    }

    public Optional<Merchant> findByPhone(String phone) throws SQLException {
        String sql = BASE_SELECT + " AND u.phone = ?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, phone);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(map(rs));
                }
            }
        }
        return Optional.empty();
    }

    /**
     * Find a merchant by email, searching only dbo.Users (no JOIN required).
     */
    public Optional<Long> findUserIdByEmail(String email) throws SQLException {
        String sql = "SELECT id FROM dbo.Users WHERE email=? AND role='MERCHANT' AND status='ACTIVE'";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(rs.getLong(1));
                }
            }
        }
        return Optional.empty();
    }

    public Optional<Merchant> findById(long userId) throws SQLException {
        String sql = BASE_SELECT + " AND u.id = ?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(map(rs));
                }
            }
        }
        return Optional.empty();
    }

    /**
     * Registers a new merchant (INSERT Users + MerchantProfiles in one
     * transaction).
     */
    public long create(String fullName, String email, String rawPassword,
            String phone, String shopName, String shopPhone,
            String shopAddressLine,
            String provinceCode, String provinceName,
            String districtCode, String districtName,
            String wardCode, String wardName) throws SQLException {

        String hash = BCrypt.hashpw(rawPassword, BCrypt.gensalt(12));
        String sqlUser = "INSERT INTO dbo.Users (full_name, email, phone, password_hash, role, status) "
                + "VALUES (?, ?, ?, ?, 'MERCHANT', 'ACTIVE')";
        String sqlProfile = "INSERT INTO dbo.MerchantProfiles "
                + "(user_id, shop_name, shop_phone, shop_address_line, "
                + " province_code, province_name, district_code, district_name, ward_code, ward_name, status) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING')";

        try (Connection c = DataSourceConfig.getConnection()) {
            c.setAutoCommit(false);
            long userId;

            try (PreparedStatement ps = c.prepareStatement(sqlUser, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, fullName);
                ps.setString(2, email);
                ps.setString(3, phone);
                ps.setString(4, hash);
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (!keys.next()) {
                        throw new SQLException("Failed to get user id");
                    }
                    userId = keys.getLong(1);
                }
            }

            try (PreparedStatement ps = c.prepareStatement(sqlProfile)) {
                ps.setLong(1, userId);
                ps.setString(2, shopName != null ? shopName : fullName);
                ps.setString(3, shopPhone != null ? shopPhone : phone);
                ps.setString(4, shopAddressLine != null ? shopAddressLine : "");
                ps.setString(5, provinceCode != null ? provinceCode : "");
                ps.setString(6, provinceName != null ? provinceName : "");
                ps.setString(7, districtCode != null ? districtCode : "");
                ps.setString(8, districtName != null ? districtName : "");
                ps.setString(9, wardCode != null ? wardCode : "");
                ps.setString(10, wardName != null ? wardName : "");
                ps.executeUpdate();
            }

            c.commit();
            return userId;
        }
    }

    public void updateProfile(long userId, String shopName, String shopPhone,
            String shopAddressLine) throws SQLException {
        String sql = "UPDATE dbo.MerchantProfiles "
                + "SET shop_name=?, shop_phone=?, shop_address_line=?, updated_at=SYSUTCDATETIME() "
                + "WHERE user_id=?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, shopName);
            ps.setString(2, shopPhone);
            ps.setString(3, shopAddressLine);
            ps.setLong(4, userId);
            ps.executeUpdate();
        }
    }

    public void updateBusinessHours(long userId, String businessHoursJson) throws SQLException {
        String sql = "UPDATE dbo.MerchantProfiles "
                + "SET business_hours=?, updated_at=SYSUTCDATETIME() "
                + "WHERE user_id=?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, businessHoursJson);
            ps.setLong(2, userId);
            ps.executeUpdate();
        }
    }

    public void updateAvatar(long userId, String avatarUrl) throws SQLException {
        String sql = "UPDATE dbo.MerchantProfiles "
                + "SET avatar_url=?, updated_at=SYSUTCDATETIME() "
                + "WHERE user_id=?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, avatarUrl);
            ps.setLong(2, userId);
            ps.executeUpdate();
        }
    }

    public void updatePassword(long userId, String newHashedPassword) throws SQLException {
        String sql = "UPDATE dbo.Users SET password_hash=?, updated_at=SYSUTCDATETIME() WHERE id=?";
        try (Connection c = DataSourceConfig.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, newHashedPassword);
            ps.setLong(2, userId);
            ps.executeUpdate();
        }
    }

    public boolean verifyPassword(String rawPassword, String storedHash) {
        if (storedHash == null || !storedHash.startsWith("$2")) {
            // Not a BCrypt hash – plain-text password stored in DB
            return rawPassword.equals(storedHash);
        }
        try {
            return BCrypt.checkpw(rawPassword, storedHash);
        } catch (Exception e) {
            return false;
        }
    }

    private Merchant map(ResultSet rs) throws SQLException {
        Merchant m = new Merchant();
        m.setUserId(rs.getLong("user_id"));
        m.setFullName(rs.getString("full_name"));
        m.setEmail(rs.getString("email"));
        m.setPhone(rs.getString("phone"));
        m.setPasswordHash(rs.getString("password_hash"));
        m.setUserStatus(rs.getString("user_status"));
        m.setShopName(rs.getString("shop_name"));
        m.setShopPhone(rs.getString("shop_phone"));
        m.setShopAddressLine(rs.getString("shop_address_line"));
        m.setProvinceName(rs.getString("province_name"));
        m.setDistrictName(rs.getString("district_name"));
        m.setWardName(rs.getString("ward_name"));
        m.setShopStatus(rs.getString("shop_status"));
        m.setBusinessHours(rs.getString("business_hours"));
        m.setAvatarUrl(rs.getString("avatar_url"));
        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) {
            m.setCreatedAt(ts.toLocalDateTime());
        }
        return m;
    }
}
