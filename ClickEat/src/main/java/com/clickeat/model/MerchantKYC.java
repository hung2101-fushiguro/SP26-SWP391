package com.clickeat.model;
import lombok.*;
import java.sql.Timestamp;
@Data
@AllArgsConstructor
@NoArgsConstructor
public class MerchantKYC {
    private int id;
    private int merchantUserId;
    private String businessName;
    private String businessLicenseNumber;
    private String documentUrl;
    private Timestamp submittedAt;
    private int reviewedByAdminId;
    private String reviewStatus;
    private String reviewNote;
}
