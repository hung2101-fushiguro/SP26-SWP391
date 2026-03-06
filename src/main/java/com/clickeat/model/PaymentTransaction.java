package com.clickeat.model;

import java.sql.Timestamp;


public class PaymentTransaction {
    private int id;
    private int orderId;
    private String provider;
    private double amount;
    private String status;
    private String providerTnxRef;
    private Timestamp createdAt;
    private Timestamp updatedAt;
    public PaymentTransaction() {
    }
    public PaymentTransaction(int id, int orderId, String provider, double amount, String status, String providerTnxRef, Timestamp createdAt, Timestamp updatedAt) {
        this.id = id;
        this.orderId = orderId;
        this.provider = provider;
        this.amount = amount;
        this.status = status;
        this.providerTnxRef = providerTnxRef;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
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
    public String getProvider() {
        return provider;
    }
    public void setProvider(String provider) {
        this.provider = provider;
    }
    public double getAmount() {
        return amount;
    }
    public void setAmount(double amount) {
        this.amount = amount;
    }
    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }
    public String getProviderTnxRef() {
        return providerTnxRef;
    }
    public void setProviderTnxRef(String providerTnxRef) {
        this.providerTnxRef = providerTnxRef;
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
