package com.SmartCanteen.Backend.DTOs;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Data
public class OrderDTO {
    private Long id;
    private Long userId; // or customerId, but your Order entity uses Customer, not userId
    private Map<Long, Integer> items; // <-- Map, not List
    private BigDecimal totalAmount;
    private String status;
    private LocalDateTime orderTime;
    private LocalDateTime scheduledTime;
}
