package com.clickeat.model;
import java.sql.Timestamp;

public class ShipperProfile {
    private int id;
    private int userId;
    private String vehicleType;
    private String status;
    private Timestamp createdAt;
    public ShipperProfile() {
    }
    public ShipperProfile(int id, int userId, String vehicleType, String status, Timestamp createdAt) {
        this.id = id;
        this.userId = userId;
        this.vehicleType = vehicleType;
        this.status = status;
        this.createdAt = createdAt;
    }
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public int getUserId() {
        return userId;
    }
    public void setUserId(int userId) {
        this.userId = userId;
    }
    public String getVehicleType() {
        return vehicleType;
    }
    public void setVehicleType(String vehicleType) {
        this.vehicleType = vehicleType;
    }
    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
