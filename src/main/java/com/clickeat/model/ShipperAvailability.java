package com.clickeat.model;
import java.sql.Timestamp;
public class ShipperAvailability {
    private int shipperUserId;
    private boolean isOnline;
    private String currentStatus;
    private double currentLatitude;
    private double currentLongitude;
    private Timestamp updatedAt;
    public ShipperAvailability() {
    }
    public ShipperAvailability(int shipperUserId, boolean isOnline, String currentStatus, double currentLatitude, double currentLongitude, Timestamp updatedAt) {
        this.shipperUserId = shipperUserId;
        this.isOnline = isOnline;
        this.currentStatus = currentStatus;
        this.currentLatitude = currentLatitude;
        this.currentLongitude = currentLongitude;
        this.updatedAt = updatedAt;
    }
    public int getShipperUserId() {
        return shipperUserId;
    }
    public void setShipperUserId(int shipperUserId) {
        this.shipperUserId = shipperUserId;
    }
    public boolean isOnline() {
        return isOnline;
    }
    public void setOnline(boolean isOnline) {
        this.isOnline = isOnline;
    }
    public String getCurrentStatus() {
        return currentStatus;
    }
    public void setCurrentStatus(String currentStatus) {
        this.currentStatus = currentStatus;
    }
    public double getCurrentLatitude() {
        return currentLatitude;
    }
    public void setCurrentLatitude(double currentLatitude) {
        this.currentLatitude = currentLatitude;
    }
    public double getCurrentLongitude() {
        return currentLongitude;
    }
    public void setCurrentLongitude(double currentLongitude) {
        this.currentLongitude = currentLongitude;
    }
    public Timestamp getUpdatedAt() {
        return updatedAt;
    }
    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }
}
