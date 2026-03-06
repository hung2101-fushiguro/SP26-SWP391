package com.clickeat.model;
import java.sql.Timestamp;
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
    public Order() {
    }
    public Order(int id, String orderCode, int customerUserId, String guestId, int merchantId, int shipperUserId, String receiverName, String receiverPhone, String deliveryAddressLine, String provinceCode, String provinceName, String districtCode, String districtName, String wardCode, String wardName, double latitude, double longitude, String deliveryNote, String paymentMethod, String paymentStatus, String orderStatus, double subtotalAmount, double deliveryFee, double discountAmount, double totalAmount, Timestamp createdAt, Timestamp acceptedAt, Timestamp readyAt, Timestamp pickedUpAt, Timestamp deliveredAt, Timestamp cancelledAt) {
        this.id = id;
        this.orderCode = orderCode;
        this.customerUserId = customerUserId;
        this.guestId = guestId;
        this.merchantId = merchantId;
        this.shipperUserId = shipperUserId;
        this.receiverName = receiverName;
        this.receiverPhone = receiverPhone;
        this.deliveryAddressLine = deliveryAddressLine;
        this.provinceCode = provinceCode;
        this.provinceName = provinceName;
        this.districtCode = districtCode;
        this.districtName = districtName;
        this.wardCode = wardCode;
        this.wardName = wardName;
        this.latitude = latitude;
        this.longitude = longitude;
        this.deliveryNote = deliveryNote;
        this.paymentMethod = paymentMethod;
        this.paymentStatus = paymentStatus;
        this.orderStatus = orderStatus;
        this.subtotalAmount = subtotalAmount;
        this.deliveryFee = deliveryFee;
        this.discountAmount = discountAmount;
        this.totalAmount = totalAmount;
        this.createdAt = createdAt;
        this.acceptedAt = acceptedAt;
        this.readyAt = readyAt;
        this.pickedUpAt = pickedUpAt;
        this.deliveredAt = deliveredAt;
        this.cancelledAt = cancelledAt;
    }
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public String getOrderCode() {
        return orderCode;
    }
    public void setOrderCode(String orderCode) {
        this.orderCode = orderCode;
    }
    public int getCustomerUserId() {
        return customerUserId;
    }
    public void setCustomerUserId(int customerUserId) {
        this.customerUserId = customerUserId;
    }
    public String getGuestId() {
        return guestId;
    }
    public void setGuestId(String guestId) {
        this.guestId = guestId;
    }
    public int getMerchantId() {
        return merchantId;
    }
    public void setMerchantId(int merchantId) {
        this.merchantId = merchantId;
    }
    public int getShipperUserId() {
        return shipperUserId;
    }
    public void setShipperUserId(int shipperUserId) {
        this.shipperUserId = shipperUserId;
    }
    public String getReceiverName() {
        return receiverName;
    }
    public void setReceiverName(String receiverName) {
        this.receiverName = receiverName;
    }
    public String getReceiverPhone() {
        return receiverPhone;
    }
    public void setReceiverPhone(String receiverPhone) {
        this.receiverPhone = receiverPhone;
    }
    public String getDeliveryAddressLine() {
        return deliveryAddressLine;
    }
    public void setDeliveryAddressLine(String deliveryAddressLine) {
        this.deliveryAddressLine = deliveryAddressLine;
    }
    public String getProvinceCode() {
        return provinceCode;
    }
    public void setProvinceCode(String provinceCode) {
        this.provinceCode = provinceCode;
    }
    public String getProvinceName() {
        return provinceName;
    }
    public void setProvinceName(String provinceName) {
        this.provinceName = provinceName;
    }
    public String getDistrictCode() {
        return districtCode;
    }
    public void setDistrictCode(String districtCode) {
        this.districtCode = districtCode;
    }
    public String getDistrictName() {
        return districtName;
    }
    public void setDistrictName(String districtName) {
        this.districtName = districtName;
    }
    public String getWardCode() {
        return wardCode;
    }
    public void setWardCode(String wardCode) {
        this.wardCode = wardCode;
    }
    public String getWardName() {
        return wardName;
    }
    public void setWardName(String wardName) {
        this.wardName = wardName;
    }
    public double getLatitude() {
        return latitude;
    }
    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }
    public double getLongitude() {
        return longitude;
    }
    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }
    public String getDeliveryNote() {
        return deliveryNote;
    }
    public void setDeliveryNote(String deliveryNote) {
        this.deliveryNote = deliveryNote;
    }
    public String getPaymentMethod() {
        return paymentMethod;
    }
    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }
    public String getPaymentStatus() {
        return paymentStatus;
    }
    public void setPaymentStatus(String paymentStatus) {
        this.paymentStatus = paymentStatus;
    }
    public String getOrderStatus() {
        return orderStatus;
    }
    public void setOrderStatus(String orderStatus) {
        this.orderStatus = orderStatus;
    }
    public double getSubtotalAmount() {
        return subtotalAmount;
    }
    public void setSubtotalAmount(double subtotalAmount) {
        this.subtotalAmount = subtotalAmount;
    }
    public double getDeliveryFee() {
        return deliveryFee;
    }
    public void setDeliveryFee(double deliveryFee) {
        this.deliveryFee = deliveryFee;
    }
    public double getDiscountAmount() {
        return discountAmount;
    }
    public void setDiscountAmount(double discountAmount) {
        this.discountAmount = discountAmount;
    }
    public double getTotalAmount() {
        return totalAmount;
    }
    public void setTotalAmount(double totalAmount) {
        this.totalAmount = totalAmount;
    }
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    public Timestamp getAcceptedAt() {
        return acceptedAt;
    }
    public void setAcceptedAt(Timestamp acceptedAt) {
        this.acceptedAt = acceptedAt;
    }
    public Timestamp getReadyAt() {
        return readyAt;
    }
    public void setReadyAt(Timestamp readyAt) {
        this.readyAt = readyAt;
    }
    public Timestamp getPickedUpAt() {
        return pickedUpAt;
    }
    public void setPickedUpAt(Timestamp pickedUpAt) {
        this.pickedUpAt = pickedUpAt;
    }
    public Timestamp getDeliveredAt() {
        return deliveredAt;
    }
    public void setDeliveredAt(Timestamp deliveredAt) {
        this.deliveredAt = deliveredAt;
    }
    public Timestamp getCancelledAt() {
        return cancelledAt;
    }
    public void setCancelledAt(Timestamp cancelledAt) {
        this.cancelledAt = cancelledAt;
    }
}
