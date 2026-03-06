package com.clickeat.service;

import com.clickeat.dao.MerchantDAO;
import com.clickeat.model.Merchant;
import org.mindrot.jbcrypt.BCrypt;

import java.sql.SQLException;
import java.util.Optional;

public class SettingsService {

    private final MerchantDAO merchantDAO = new MerchantDAO();

    public Optional<Merchant> getProfile(long merchantUserId) throws SQLException {
        return merchantDAO.findById(merchantUserId);
    }

    /**
     * Update shop name / phone / address line.
     */
    public Merchant updateProfile(long merchantUserId, String shopName, String shopPhone,
            String shopAddressLine) throws SQLException {
        merchantDAO.updateProfile(merchantUserId, shopName, shopPhone, shopAddressLine);
        return merchantDAO.findById(merchantUserId).orElseThrow();
    }

    /**
     * Update avatar URL (base64 data URL or external URL).
     */
    public Merchant updateAvatar(long merchantUserId, String avatarUrl) throws SQLException {
        merchantDAO.updateAvatar(merchantUserId, avatarUrl);
        return merchantDAO.findById(merchantUserId).orElseThrow();
    }

    /**
     * Update operating hours (JSON string).
     */
    public Merchant updateBusinessHours(long merchantUserId, String businessHoursJson) throws SQLException {
        merchantDAO.updateBusinessHours(merchantUserId, businessHoursJson);
        return merchantDAO.findById(merchantUserId).orElseThrow();
    }

    /**
     * Change password after verifying the current one. Returns false if current
     * password wrong.
     */

    public boolean changePassword(long merchantUserId, String currentPassword,
            String newPassword) throws SQLException {
        Merchant m = merchantDAO.findById(merchantUserId)
                .orElseThrow(() -> new IllegalArgumentException("Merchant not found"));

        if (!merchantDAO.verifyPassword(currentPassword, m.getPasswordHash())) {
            return false;
        }

        String newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt(12));
        merchantDAO.updatePassword(merchantUserId, newHash);
        return true;
    }
}
