package com.clickeat.model;

import java.time.LocalDateTime;

/**
 * Maps to dbo.Ratings (target_type = 'MERCHANT'). The real schema has no
 * merchant-reply column.
 */
public class ReviewModel {

    private long id;
    private long orderId;          // Ratings.order_id
    private long targetUserId;     // Ratings.target_user_id (= merchant user_id)
    private String raterName;        // joined from Users.full_name
    private int stars;            // Ratings.stars (1-5)
    private String comment;          // Ratings.comment
    private LocalDateTime createdAt; // Ratings.created_at

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public long getOrderId() {
        return orderId;
    }

    public void setOrderId(long orderId) {
        this.orderId = orderId;
    }

    public long getTargetUserId() {
        return targetUserId;
    }

    public void setTargetUserId(long targetUserId) {
        this.targetUserId = targetUserId;
    }

    public String getRaterName() {
        return raterName;
    }

    public void setRaterName(String raterName) {
        this.raterName = raterName;
    }

    public int getStars() {
        return stars;
    }

    public void setStars(int stars) {
        this.stars = stars;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
