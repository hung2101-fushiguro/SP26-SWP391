package com.clickeat.model;
import lombok.*;
import java.sql.Timestamp;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Rating {
    private int id;
    private int orderId;
    private int raterCustomerId;
    private int raterGuestId;
    private String targetType;
    private int targetUserId;
    private int stars;
    private String comment;
    private Timestamp createdAt;
}
