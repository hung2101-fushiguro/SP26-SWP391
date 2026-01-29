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
    private int provinceCode;
    private String provinceName;
    private int districtCode;
    private String districtName;
    private int wardCode;
    private String wardName;
    private double latitude;
    private double longitude;
    private Boolean isDefault;
    private String note;
    private String status;
    private Timestamp createdAt;
    private Timestamp updatedAt;
}
