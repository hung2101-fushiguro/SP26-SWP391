package com.clickeat.model;
import lombok.*;
import java.sql.Timestamp;
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Order {
    private int id;
    private String orderCode;
    private int customerUserId;
    private String guestId;
    private int merchantId;
    private int shipperUserId;
    private String receiverName;
    private String receiverPhone;
    private String deliveryAddressLine;
    private String provinceCode;
    private String provinceName;
    private String districtCode;
    private String districtName;
    private String wardCode;
    private String wardName;
    private double latitude;
    private double longitude;
    private String deliveryNote;
    private String paymentMethod;
    private String paymentStatus;
    private String orderStatus;
    private double subtotalAmount;
    private double deliveryFee;
    private double discountAmount;
    private double totalAmount;
    private Timestamp createdAt;
    private Timestamp acceptedAt;
    private Timestamp readyAt;
    private Timestamp pickedUpAt;
    private Timestamp deliveredAt;
    private Timestamp cancelledAt;
}
