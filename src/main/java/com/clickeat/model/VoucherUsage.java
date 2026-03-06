package com.clickeat.model;

import java.sql.Timestamp;
public class VoucherUsage {
    private int id;
    private int voucherId;
    private int orderId;
    private int customerUserId;
    private String guestId;
    private Timestamp usedAt;
    public VoucherUsage() {
    }
    public VoucherUsage(int id, int voucherId, int orderId, int customerUserId, String guestId, Timestamp usedAt) {
        this.id = id;
        this.voucherId = voucherId;
        this.orderId = orderId;
        this.customerUserId = customerUserId;
        this.guestId = guestId;
        this.usedAt = usedAt;
    }
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public int getVoucherId() {
        return voucherId;
    }
    public void setVoucherId(int voucherId) {
        this.voucherId = voucherId;
    }
    public int getOrderId() {
        return orderId;
    }
    public void setOrderId(int orderId) {
        this.orderId = orderId;
    }
    public int getCustomerUserId() {
        return customerUserId;
    }
    public void setCustomerUserId(int customerUserId) {
        this.customerUserId = customerUserId;
    }
    public String getGuestId() {
        return guestId;
    }
    public void setGuestId(String guestId) {
        this.guestId = guestId;
    }
    public Timestamp getUsedAt() {
        return usedAt;
    }
    public void setUsedAt(Timestamp usedAt) {
        this.usedAt = usedAt;
    }
}
