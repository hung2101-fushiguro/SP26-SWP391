package com.clickeat.model;

import java.time.LocalDateTime;

/**
 * Merged view of dbo.Users (role='MERCHANT') + dbo.MerchantProfiles. Primary
 * key is Users.id (= MerchantProfiles.user_id).
 */
public class Merchant {

    private long userId;          // Users.id  (also MerchantProfiles.user_id)
    private String fullName;        // Users.full_name
    private String email;           // Users.email
    private String phone;           // Users.phone
    private String passwordHash;    // Users.password_hash  (never sent to client)
    private String userStatus;      // Users.status  (ACTIVE/INACTIVE)

    // MerchantProfiles columns
    private String shopName;        // MerchantProfiles.shop_name
    private String shopPhone;       // MerchantProfiles.shop_phone
    private String shopAddressLine; // MerchantProfiles.shop_address_line
    private String provinceName;
    private String districtName;
    private String wardName;
    private String shopStatus;      // MerchantProfiles.status (PENDING/APPROVED/REJECTED/SUSPENDED)
    private String businessHours;    // MerchantProfiles.business_hours (JSON)
    private String avatarUrl;          // MerchantProfiles.avatar_url

    private LocalDateTime createdAt; // Users.created_at

    public long getUserId() {
        return userId;
    }

    public void setUserId(long userId) {
        this.userId = userId;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public String getUserStatus() {
        return userStatus;
    }

    public void setUserStatus(String userStatus) {
        this.userStatus = userStatus;
    }

    public String getShopName() {
        return shopName;
    }

    public void setShopName(String shopName) {
        this.shopName = shopName;
    }

    public String getShopPhone() {
        return shopPhone;
    }

    public void setShopPhone(String shopPhone) {
        this.shopPhone = shopPhone;
    }

    public String getShopAddressLine() {
        return shopAddressLine;
    }

    public void setShopAddressLine(String shopAddressLine) {
        this.shopAddressLine = shopAddressLine;
    }

    public String getProvinceName() {
        return provinceName;
    }

    public void setProvinceName(String provinceName) {
        this.provinceName = provinceName;
    }

    public String getDistrictName() {
        return districtName;
    }

    public void setDistrictName(String districtName) {
        this.districtName = districtName;
    }

    public String getWardName() {
        return wardName;
    }

    public void setWardName(String wardName) {
        this.wardName = wardName;
    }

    public String getShopStatus() {
        return shopStatus;
    }

    public void setShopStatus(String shopStatus) {
        this.shopStatus = shopStatus;
    }

    public String getBusinessHours() {
        return businessHours;
    }

    public void setBusinessHours(String businessHours) {
        this.businessHours = businessHours;
    }

    public String getAvatarUrl() {
        return avatarUrl;
    }

    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
