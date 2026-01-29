package com.clickeat.model;

import lombok.*;
import java.sql.Timestamp;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class VoucherUsage {
    private int id;
    private int voucherId;
    private int orderId;
    private int customerUserId;
    private String guestId;
    private Timestamp usedAt;
}
