package com.clickeat.model;
import lombok.*;
import java.sql.Timestamp;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class GuestSession {
    private String guestId;
    private String contactPhone;
    private String contactEmail;
    private Timestamp createdAt;
    private Timestamp expiresAt;
}
