package com.clickeat.model;
import lombok.*;
import java.sql.Timestamp;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ShipperProfile {
    private int id;
    private int userId;
    private String vehicleType;
    private String status;
    private Timestamp createdAt;
}
