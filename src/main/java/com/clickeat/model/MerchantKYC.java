package com.clickeat.model;
import java.sql.Timestamp;
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
    public MerchantKYC() {
    }
    public MerchantKYC(int id, int merchantUserId, String businessName, String businessLicenseNumber, String documentUrl, Timestamp submittedAt, int reviewedByAdminId, String reviewStatus, String reviewNote) {
        this.id = id;
        this.merchantUserId = merchantUserId;
        this.businessName = businessName;
        this.businessLicenseNumber = businessLicenseNumber;
        this.documentUrl = documentUrl;
        this.submittedAt = submittedAt;
        this.reviewedByAdminId = reviewedByAdminId;
        this.reviewStatus = reviewStatus;
        this.reviewNote = reviewNote;
    }
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public int getMerchantUserId() {
        return merchantUserId;
    }
    public void setMerchantUserId(int merchantUserId) {
        this.merchantUserId = merchantUserId;
    }
    public String getBusinessName() {
        return businessName;
    }
    public void setBusinessName(String businessName) {
        this.businessName = businessName;
    }
    public String getBusinessLicenseNumber() {
        return businessLicenseNumber;
    }
    public void setBusinessLicenseNumber(String businessLicenseNumber) {
        this.businessLicenseNumber = businessLicenseNumber;
    }
    public String getDocumentUrl() {
        return documentUrl;
    }
    public void setDocumentUrl(String documentUrl) {
        this.documentUrl = documentUrl;
    }
    public Timestamp getSubmittedAt() {
        return submittedAt;
    }
    public void setSubmittedAt(Timestamp submittedAt) {
        this.submittedAt = submittedAt;
    }
    public int getReviewedByAdminId() {
        return reviewedByAdminId;
    }
    public void setReviewedByAdminId(int reviewedByAdminId) {
        this.reviewedByAdminId = reviewedByAdminId;
    }
    public String getReviewStatus() {
        return reviewStatus;
    }
    public void setReviewStatus(String reviewStatus) {
        this.reviewStatus = reviewStatus;
    }
    public String getReviewNote() {
        return reviewNote;
    }
    public void setReviewNote(String reviewNote) {
        this.reviewNote = reviewNote;
    }
}
