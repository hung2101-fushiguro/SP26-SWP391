package com.clickeat.model;
import lombok.*;
import java.sql.Timestamp;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ShipperAvailability {
    private int shipperUserId;
    private boolean isOnline;
    private String currentStatus;
    private double currentLatitude;
    private double currentLongitude;
    private Timestamp updatedAt;
}
