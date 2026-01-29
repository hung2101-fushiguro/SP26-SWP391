package com.clickeat.model;
import lombok.*;
import java.sql.Timestamp;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderStatusHistory {
    private int id;
    private int orderId;
    private String fromStatus;
    private String toStatus;
    private String updatedByRole;
    private int updatedByUserId;
    private String note;
    private Timestamp createdAt;
}
