package com.clickeat.model;
import lombok.*;
import java.sql.Timestamp;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Voucher {
    private int id;
    private String code;
    private String discountType;
    private double discountValue;
    private double minOrderAmount;
    private Timestamp startAt;
    private Timestamp endAt;
    private String status;
}
