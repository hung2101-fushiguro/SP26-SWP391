package com.clickeat.model;
import lombok.*;
import java.sql.Timestamp;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Cart {
    private int id;
    private int customerUserId;
    private String guestId;
    private String status;
    private Timestamp createdAt;
    private Timestamp updatedAt;
}
