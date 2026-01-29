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
    private Timestamp createdAt;
    private Timestamp updatedAt;
}
