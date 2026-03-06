package com.clickeat.model;
import java.sql.Timestamp;
public class MerchantProfile {
    private int userId;
    private String shopName;
    private String shopPhone;
    private String shopAddressLine;
    private String provinceCode;
    private String provinceName;
    private String districtCode;
    private String districtName;
    private String wardCode;
    private String wardName;
    private double latitude;
    private double longitude;
    private Boolean isDefault;
    private String note;
    private String status;
    private Timestamp createdAt;
    private Timestamp updatedAt;
    public MerchantProfile() {
    }
    public MerchantProfile(int userId, String shopName, String shopPhone, String shopAddressLine, String provinceCode, String provinceName, String districtCode, String districtName, String wardCode, String wardName, double latitude, double longitude, Boolean isDefault, String note, String status, Timestamp createdAt, Timestamp updatedAt) {
        this.userId = userId;
        this.shopName = shopName;
        this.shopPhone = shopPhone;
        this.shopAddressLine = shopAddressLine;
        this.provinceCode = provinceCode;
        this.provinceName = provinceName;
        this.districtCode = districtCode;
        this.districtName = districtName;
        this.wardCode = wardCode;
        this.wardName = wardName;
        this.latitude = latitude;
        this.longitude = longitude;
        this.isDefault = isDefault;
        this.note = note;
        this.status = status;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
    public int getUserId() {
        return userId;
    }
    public void setUserId(int userId) {
        this.userId = userId;
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
    public String getProvinceCode() {
        return provinceCode;
    }
    public void setProvinceCode(String provinceCode) {
        this.provinceCode = provinceCode;
    }
    public String getProvinceName() {
        return provinceName;
    }
    public void setProvinceName(String provinceName) {
        this.provinceName = provinceName;
    }
    public String getDistrictCode() {
        return districtCode;
    }
    public void setDistrictCode(String districtCode) {
        this.districtCode = districtCode;
    }
    public String getDistrictName() {
        return districtName;
    }
    public void setDistrictName(String districtName) {
        this.districtName = districtName;
    }
    public String getWardCode() {
        return wardCode;
    }
    public void setWardCode(String wardCode) {
        this.wardCode = wardCode;
    }
    public String getWardName() {
        return wardName;
    }
    public void setWardName(String wardName) {
        this.wardName = wardName;
    }
    public double getLatitude() {
        return latitude;
    }
    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }
    public double getLongitude() {
        return longitude;
    }
    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }
    public Boolean getIsDefault() {
        return isDefault;
    }
    public void setIsDefault(Boolean isDefault) {
        this.isDefault = isDefault;
    }
    public String getNote() {
        return note;
    }
    public void setNote(String note) {
        this.note = note;
    }
    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    public Timestamp getUpdatedAt() {
        return updatedAt;
    }
    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }
}
