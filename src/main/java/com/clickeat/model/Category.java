package com.clickeat.model;

public class Category {
    private int id;
    private int merchantUserId;
    private String name;
    private boolean isActive;
    private int sortOrder;
    public Category() {
    }
    public Category(int id, int merchantUserId, String name, boolean isActive, int sortOrder) {
        this.id = id;
        this.merchantUserId = merchantUserId;
        this.name = name;
        this.isActive = isActive;
        this.sortOrder = sortOrder;
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
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public boolean isActive() {
        return isActive;
    }
    public void setActive(boolean isActive) {
        this.isActive = isActive;
    }
    public int getSortOrder() {
        return sortOrder;
    }
    public void setSortOrder(int sortOrder) {
        this.sortOrder = sortOrder;
    }
}
