package com.clickeat.model;
import java.sql.Timestamp;

public class OrderStatusHistory {
    private int id;
    private int orderId;
    private String fromStatus;
    private String toStatus;
    private String updatedByRole;
    private int updatedByUserId;
    private String note;
    private Timestamp createdAt;
    public OrderStatusHistory() {
    }
    public OrderStatusHistory(int id, int orderId, String fromStatus, String toStatus, String updatedByRole, int updatedByUserId, String note, Timestamp createdAt) {
        this.id = id;
        this.orderId = orderId;
        this.fromStatus = fromStatus;
        this.toStatus = toStatus;
        this.updatedByRole = updatedByRole;
        this.updatedByUserId = updatedByUserId;
        this.note = note;
        this.createdAt = createdAt;
    }
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public int getOrderId() {
        return orderId;
    }
    public void setOrderId(int orderId) {
        this.orderId = orderId;
    }
    public String getFromStatus() {
        return fromStatus;
    }
    public void setFromStatus(String fromStatus) {
        this.fromStatus = fromStatus;
    }
    public String getToStatus() {
        return toStatus;
    }
    public void setToStatus(String toStatus) {
        this.toStatus = toStatus;
    }
    public String getUpdatedByRole() {
        return updatedByRole;
    }
    public void setUpdatedByRole(String updatedByRole) {
        this.updatedByRole = updatedByRole;
    }
    public int getUpdatedByUserId() {
        return updatedByUserId;
    }
    public void setUpdatedByUserId(int updatedByUserId) {
        this.updatedByUserId = updatedByUserId;
    }
    public String getNote() {
        return note;
    }
    public void setNote(String note) {
        this.note = note;
    }
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
