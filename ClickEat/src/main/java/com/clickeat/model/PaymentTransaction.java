package com.clickeat.model;
import lombok.*;
import java.sql.Timestamp;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PaymentTransaction {
    private int id;
    private int orderId;
    private String provider;
    private double amount;
    private String status;
    private String providerTnxRef;
    private Timestamp createdAt;
    private Timestamp updatedAt;
}
