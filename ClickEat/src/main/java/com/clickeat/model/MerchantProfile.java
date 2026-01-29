package com.clickeat.model;
import lombok.*;
import java.sql.Timestamp;
@Data
@AllArgsConstructor
@NoArgsConstructor
public class MerchantProfile {
    private int userId;
    private String shopName;
    private String shopPhone;
    private String shopAddressLine;
    private String provinceCode;
    private String provinceName;
    private String districtCode;
    private String districtName;
    private String wardCode;
    private String wardName;
    private double latitude;
    private double longitude;
    private Boolean isDefault;
    private String note;
    private String status;
    private Timestamp createdAt;
    private Timestamp updatedAt;
}
