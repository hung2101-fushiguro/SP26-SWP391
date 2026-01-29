package com.clickeat.model;
import lombok.*;

import java.sql.Timestamp;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserAuthProvider {
    private int id;
    private int userId;
    private String provider;
    private String providerUserId;
    private Timestamp linkedAt;
}
