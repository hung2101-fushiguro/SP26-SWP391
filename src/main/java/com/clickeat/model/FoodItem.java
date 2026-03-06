package com.clickeat.model;

import java.sql.Timestamp;

public class FoodItem {
    private int id;
    private int merchantUserId;
    private int categoryId;
    private String name;
    private String description;
    private double price;
    private String imageUrl;
    private boolean isAvailable;
    private boolean isFried;
    private Timestamp createdAt;
    private Timestamp updatedAt;
    public FoodItem() {
    }
    public FoodItem(int id, int merchantUserId, int categoryId, String name, String description, double price, String imageUrl, boolean isAvailable, boolean isFried, Timestamp createdAt, Timestamp updatedAt) {
        this.id = id;
        this.merchantUserId = merchantUserId;
        this.categoryId = categoryId;
        this.name = name;
        this.description = description;
        this.price = price;
        this.imageUrl = imageUrl;
        this.isAvailable = isAvailable;
        this.isFried = isFried;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public int getMerchantUserId() {
        return merchantUserId;
    }
    public void setMerchantUserId(int merchantUserId) {
        this.merchantUserId = merchantUserId;
    }
    public int getCategoryId() {
        return categoryId;
    }
    public void setCategoryId(int categoryId) {
        this.categoryId = categoryId;
    }
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public String getDescription() {
        return description;
    }
    public void setDescription(String description) {
        this.description = description;
    }
    public double getPrice() {
        return price;
    }
    public void setPrice(double price) {
        this.price = price;
    }
    public String getImageUrl() {
        return imageUrl;
    }
    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
    public boolean isAvailable() {
        return isAvailable;
    }
    public void setAvailable(boolean available) {
        isAvailable = available;
    }
    public boolean isFried() {
        return isFried;
    }
    public void setFried(boolean fried) {
        isFried = fried;
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
