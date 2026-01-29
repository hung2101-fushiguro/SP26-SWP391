package com.clickeat.model;
import lombok.*;
@Data
@AllArgsConstructor
@NoArgsConstructor
public class CartItem {
    private int id;
    private int cartId;
    private int foodItemId;
    private int quantity;
    private double unitPriceSnapshot;
    private String note;
}
