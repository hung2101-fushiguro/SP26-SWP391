package com.clickeat.model;

/**
 * Maps to dbo.Categories. Note: no description column in the real schema.
 */
public class CategoryModel {

    private long id;               // Categories.id (BIGINT)
    private long merchantUserId;   // Categories.merchant_user_id
    private String name;             // Categories.name
    private boolean isActive;         // Categories.is_active
    private int sortOrder;        // Categories.sort_order

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public long getMerchantUserId() {
        return merchantUserId;
    }

    public void setMerchantUserId(long merchantUserId) {
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

    public void setActive(boolean active) {
        this.isActive = active;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(int sortOrder) {
        this.sortOrder = sortOrder;
    }
}
