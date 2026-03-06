package com.clickeat.model;

import java.sql.Timestamp;

public class Notification {

    private int id;
    private int userId;
    private String guestId;
    private String type;
    private String content;
    private Long referenceId; // order_id / chat_id / rating_id
    private boolean isRead;//0: chưa đọc, 1: đã đọc
    private Timestamp createdAt;

    public Notification() {
    }

    public Notification(int id, int userId, String guestId, String type, String content, Long referenceId, boolean isRead, Timestamp createdAt) {
        this.id = id;
        this.userId = userId;
        this.guestId = guestId;
        this.type = type;
        this.content = content;
        this.referenceId = referenceId;
        this.isRead = isRead;
        this.createdAt = createdAt;
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

    public String getGuestId() {
        return guestId;
    }

    public void setGuestId(String guestId) {
        this.guestId = guestId;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Long getReferenceId() {
        return referenceId;
    }

    public void setReferenceId(Long referenceId) {
        this.referenceId = referenceId;
    }

    public boolean isRead() {
        return isRead;
    }

    public void setRead(boolean isRead) {
        this.isRead = isRead;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
