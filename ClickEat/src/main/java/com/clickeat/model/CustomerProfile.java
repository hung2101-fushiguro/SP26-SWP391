package com.clickeat.model;
import lombok.*;

import java.sql.Timestamp;

@Data
@NoArgsConstructor@AllArgsConstructor
public class CustomerProfile {
    private int userId;
    private int defaultAddressId;
    private Timestamp createdAt;
    private Timestamp updatedAt;
}
