package com.clickeat.model;
public class OrderItem {
    private int id;
    private int orderId;
    private int foodItemId;
    private String itemNameSnapshot;
    private double unitPriceSnapshot;
    private int quantity;
    private String note;
    public OrderItem() {
    }
    public OrderItem(int id, int orderId, int foodItemId, String itemNameSnapshot, double unitPriceSnapshot, int quantity, String note) {
        this.id = id;
        this.orderId = orderId;
        this.foodItemId = foodItemId;
        this.itemNameSnapshot = itemNameSnapshot;
        this.unitPriceSnapshot = unitPriceSnapshot;
        this.quantity = quantity;
        this.note = note;
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
    public int getFoodItemId() {
        return foodItemId;
    }
    public void setFoodItemId(int foodItemId) {
        this.foodItemId = foodItemId;
    }
    public String getItemNameSnapshot() {
        return itemNameSnapshot;
    }
    public void setItemNameSnapshot(String itemNameSnapshot) {
        this.itemNameSnapshot = itemNameSnapshot;
    }
    public double getUnitPriceSnapshot() {
        return unitPriceSnapshot;
    }
    public void setUnitPriceSnapshot(double unitPriceSnapshot) {
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
