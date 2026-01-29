package com.clickeat.model;
import lombok.*;
import java.sql.Timestamp;
@Data
@AllArgsConstructor
@NoArgsConstructor
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
}
