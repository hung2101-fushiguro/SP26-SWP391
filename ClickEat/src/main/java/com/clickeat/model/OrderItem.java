package com.clickeat.model;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderItem {
    private int id;
    private int orderId;
    private int foodItemId;
    private String itemNameSnapshot;
    private double unitPriceSnapshot;
    private int quantity;
    private String note;
}
