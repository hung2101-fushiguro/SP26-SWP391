package com.clickeat.model;
import lombok.*;
import java.sql.Timestamp;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserBehaviorEvent {
    private int id;
    private int customerUserId;
    private String eventType;
    private int foodItemId;
    private String keyword;
    private Timestamp createdAt;
}
