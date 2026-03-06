package com.clickeat.model;

import java.sql.Timestamp;



public class CustomerProfile {
    private int userId;
    private int defaultAddressId;
    private Timestamp createdAt;
    private Timestamp updatedAt;
    public CustomerProfile() {
    }
    public CustomerProfile(int userId, int defaultAddressId, Timestamp createdAt, Timestamp updatedAt) {
        this.userId = userId;
        this.defaultAddressId = defaultAddressId;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
    public int getUserId() {
        return userId;
    }
    public void setUserId(int userId) {
        this.userId = userId;
    }
    public int getDefaultAddressId() {
        return defaultAddressId;
    }
    public void setDefaultAddressId(int defaultAddressId) {
        this.defaultAddressId = defaultAddressId;
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
