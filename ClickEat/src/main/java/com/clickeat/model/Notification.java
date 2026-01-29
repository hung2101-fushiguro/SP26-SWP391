package com.clickeat.model;
import lombok.*;
import java.sql.Timestamp;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Notification {
    private int id;
    private int userId;
    private String guestId;
    private String type;
    private String content;
    private boolean isRead;//0: chưa đọc, 1: đã đọc
    private Timestamp createdAt;
}
