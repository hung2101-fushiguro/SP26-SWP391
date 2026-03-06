package com.clickeat.model;

import java.sql.Timestamp;

public class UserBehaviorEvent {
    private int id;
    private int customerUserId;
    private String eventType;
    private int foodItemId;
    private String keyword;
    private Timestamp createdAt;
    public UserBehaviorEvent() {
    }
    public UserBehaviorEvent(int id, int customerUserId, String eventType, int foodItemId, String keyword, Timestamp createdAt) {
        this.id = id;
        this.customerUserId = customerUserId;
        this.eventType = eventType;
        this.foodItemId = foodItemId;
        this.keyword = keyword;
        this.createdAt = createdAt;
    }
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public int getCustomerUserId() {
        return customerUserId;
    }
    public void setCustomerUserId(int customerUserId) {
        this.customerUserId = customerUserId;
    }
    public String getEventType() {
        return eventType;
    }
    public void setEventType(String eventType) {
        this.eventType = eventType;
    }
    public int getFoodItemId() {
        return foodItemId;
    }
    public void setFoodItemId(int foodItemId) {
        this.foodItemId = foodItemId;
    }
    public String getKeyword() {
        return keyword;
    }
    public void setKeyword(String keyword) {
        this.keyword = keyword;
    }
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
