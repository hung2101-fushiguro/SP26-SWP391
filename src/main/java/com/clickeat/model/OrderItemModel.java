package com.clickeat.model;

import java.math.BigDecimal;

/**
 * Maps to dbo.OrderItems.
 */
public class OrderItemModel {

    private long id;
    private long orderId;           // OrderItems.order_id
    private long foodItemId;        // OrderItems.food_item_id
    private String itemNameSnapshot;  // OrderItems.item_name_snapshot
    private BigDecimal unitPriceSnapshot; // OrderItems.unit_price_snapshot
    private int quantity;
    private String note;              // OrderItems.note

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public long getOrderId() {
        return orderId;
    }

    public void setOrderId(long orderId) {
        this.orderId = orderId;
    }

    public long getFoodItemId() {
        return foodItemId;
    }

    public void setFoodItemId(long foodItemId) {
        this.foodItemId = foodItemId;
    }

    public String getItemNameSnapshot() {
        return itemNameSnapshot;
    }

    public void setItemNameSnapshot(String itemNameSnapshot) {
        this.itemNameSnapshot = itemNameSnapshot;
    }

    public BigDecimal getUnitPriceSnapshot() {
        return unitPriceSnapshot;
    }

    public void setUnitPriceSnapshot(BigDecimal unitPriceSnapshot) {
        this.unitPriceSnapshot = unitPriceSnapshot;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }
}
