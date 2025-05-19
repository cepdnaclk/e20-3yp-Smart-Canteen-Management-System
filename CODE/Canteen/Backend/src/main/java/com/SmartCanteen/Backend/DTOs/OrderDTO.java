package com.SmartCanteen.Backend.DTOs;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

@Data
public class OrderDTO {
    private Long id;
    private Long customerId;
    private Map<Long, Integer> items; // menuItemId -> quantity
    private BigDecimal totalAmount;
    private String status; // e.g., PENDING, COMPLETED, CANCELLED
    private LocalDateTime orderTime;
    private LocalDateTime scheduledTime; // nullable for immediate orders
}
