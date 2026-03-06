package com.clickeat.model;
import java.sql.Timestamp;
public class Voucher {
    private int id;
    private String code;
    private String discountType;
    private double discountValue;
    private double minOrderAmount;
    private Timestamp startAt;
    private Timestamp endAt;
    private String status;
    public Voucher() {
    }
    public Voucher(int id, String code, String discountType, double discountValue, double minOrderAmount, Timestamp startAt, Timestamp endAt, String status) {
        this.id = id;
        this.code = code;
        this.discountType = discountType;
        this.discountValue = discountValue;
        this.minOrderAmount = minOrderAmount;
        this.startAt = startAt;
        this.endAt = endAt;
        this.status = status;
    }
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public String getCode() {
        return code;
    }
    public void setCode(String code) {
        this.code = code;
    }
    public String getDiscountType() {
        return discountType;
    }
    public void setDiscountType(String discountType) {
        this.discountType = discountType;
    }
    public double getDiscountValue() {
        return discountValue;
    }
    public void setDiscountValue(double discountValue) {
        this.discountValue = discountValue;
    }
    public double getMinOrderAmount() {
        return minOrderAmount;
    }
    public void setMinOrderAmount(double minOrderAmount) {
        this.minOrderAmount = minOrderAmount;
    }
    public Timestamp getStartAt() {
        return startAt;
    }
    public void setStartAt(Timestamp startAt) {
        this.startAt = startAt;
    }
    public Timestamp getEndAt() {
        return endAt;
    }
    public void setEndAt(Timestamp endAt) {
        this.endAt = endAt;
    }
    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }
}
