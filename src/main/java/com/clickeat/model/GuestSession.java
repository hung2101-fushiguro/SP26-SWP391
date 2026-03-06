package com.clickeat.model;

import java.sql.Timestamp;
public class GuestSession {
    private String guestId;
    private String contactPhone;
    private String contactEmail;
    private Timestamp createdAt;
    private Timestamp expiresAt;
    public GuestSession() {
    }
    public GuestSession(String guestId, String contactPhone, String contactEmail, Timestamp createdAt, Timestamp expiresAt) {
        this.guestId = guestId;
        this.contactPhone = contactPhone;
        this.contactEmail = contactEmail;
        this.createdAt = createdAt;
        this.expiresAt = expiresAt;
    }
    public String getGuestId() {
        return guestId;
    }
    public void setGuestId(String guestId) {
        this.guestId = guestId;
    }
    public String getContactPhone() {
        return contactPhone;
    }
    public void setContactPhone(String contactPhone) {
        this.contactPhone = contactPhone;
    }
    public String getContactEmail() {
        return contactEmail;
    }
    public void setContactEmail(String contactEmail) {
        this.contactEmail = contactEmail;
    }
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    public Timestamp getExpiresAt() {
        return expiresAt;
    }
    public void setExpiresAt(Timestamp expiresAt) {
        this.expiresAt = expiresAt;
    }
}
