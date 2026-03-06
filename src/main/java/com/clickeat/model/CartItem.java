package com.clickeat.model;


public class CartItem {
    private int id;
    private int cartId;
    private int foodItemId;
    private int quantity;
    private double unitPriceSnapshot;
    private String note;
    public CartItem() {
    }
    public CartItem(int id, int cartId, int foodItemId, int quantity, double unitPriceSnapshot, String note) {
        this.id = id;
        this.cartId = cartId;
        this.foodItemId = foodItemId;
        this.quantity = quantity;
        this.unitPriceSnapshot = unitPriceSnapshot;
        this.note = note;
    }
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public int getCartId() {
        return cartId;
    }
    public void setCartId(int cartId) {
        this.cartId = cartId;
    }
    public int getFoodItemId() {
        return foodItemId;
    }
    public void setFoodItemId(int foodItemId) {
        this.foodItemId = foodItemId;
    }
    public int getQuantity() {
        return quantity;
    }
    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }
    public double getUnitPriceSnapshot() {
        return unitPriceSnapshot;
    }
    public void setUnitPriceSnapshot(double unitPriceSnapshot) {
        this.unitPriceSnapshot = unitPriceSnapshot;
    }
    public String getNote() {
        return note;
    }
    public void setNote(String note) {
        this.note = note;
    }
}
