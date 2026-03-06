package com.clickeat.model;
import java.sql.Timestamp;

public class Rating {
    private int id;
    private int orderId;
    private int raterCustomerId;
    private int raterGuestId;
    private String targetType;
    private int targetUserId;
    private int stars;
    private String comment;
    private Timestamp createdAt;
    public Rating() {
    }
    public Rating(int id, int orderId, int raterCustomerId, int raterGuestId, String targetType, int targetUserId, int stars, String comment, Timestamp createdAt) {
        this.id = id;
        this.orderId = orderId;
        this.raterCustomerId = raterCustomerId;
        this.raterGuestId = raterGuestId;
        this.targetType = targetType;
        this.targetUserId = targetUserId;
        this.stars = stars;
        this.comment = comment;
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
    public int getRaterCustomerId() {
        return raterCustomerId;
    }
    public void setRaterCustomerId(int raterCustomerId) {
        this.raterCustomerId = raterCustomerId;
    }
    public int getRaterGuestId() {
        return raterGuestId;
    }
    public void setRaterGuestId(int raterGuestId) {
        this.raterGuestId = raterGuestId;
    }
    public String getTargetType() {
        return targetType;
    }
    public void setTargetType(String targetType) {
        this.targetType = targetType;
    }
    public int getTargetUserId() {
        return targetUserId;
    }
    public void setTargetUserId(int targetUserId) {
        this.targetUserId = targetUserId;
    }
    public int getStars() {
        return stars;
    }
    public void setStars(int stars) {
        this.stars = stars;
    }
    public String getComment() {
        return comment;
    }
    public void setComment(String comment) {
        this.comment = comment;
    }
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
