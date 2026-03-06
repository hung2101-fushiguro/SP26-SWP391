package com.clickeat.model;

import java.sql.Timestamp;


public class UserAuthProvider {
    private int id;
    private int userId;
    private String provider;
    private String providerUserId;
    private Timestamp linkedAt;
    public UserAuthProvider() {
    }
    public UserAuthProvider(int id, int userId, String provider, String providerUserId, Timestamp linkedAt) {
        this.id = id;
        this.userId = userId;
        this.provider = provider;
        this.providerUserId = providerUserId;
        this.linkedAt = linkedAt;
    }
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public int getUserId() {
        return userId;
    }
    public void setUserId(int userId) {
        this.userId = userId;
    }
    public String getProvider() {
        return provider;
    }
    public void setProvider(String provider) {
        this.provider = provider;
    }
    public String getProviderUserId() {
        return providerUserId;
    }
    public void setProviderUserId(String providerUserId) {
        this.providerUserId = providerUserId;
    }
    public Timestamp getLinkedAt() {
        return linkedAt;
    }
    public void setLinkedAt(Timestamp linkedAt) {
        this.linkedAt = linkedAt;
    }
}
