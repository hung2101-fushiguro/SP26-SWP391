package com.clickeat.model;
import java.sql.Timestamp;

import lombok.*;
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Address {
    private int id;
    private int userId;
    private String receiverName;
    private String receiverPhone;
    private String addressLine;
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
    private Timestamp createdAt;
    private Timestamp updatedAt;
}
