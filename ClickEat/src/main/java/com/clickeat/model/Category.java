package com.clickeat.model;
import lombok.*;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Category {
    private int id;
    private int merchantUserId;
    private String name;
    private boolean isActive;
    private int sortOrder;
}
