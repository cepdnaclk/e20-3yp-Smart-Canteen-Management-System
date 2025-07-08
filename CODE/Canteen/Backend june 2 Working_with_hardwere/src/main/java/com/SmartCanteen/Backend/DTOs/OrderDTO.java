package com.SmartCanteen.Backend.DTOs;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

@Data
public class OrderDTO {
    private Long id;
    private String email;
    private Map<String, Integer> items; // Change from Map<Long, Integer>
    private BigDecimal totalAmount;
    private String status;
    private LocalDateTime orderTime;
    private LocalDateTime scheduledTime;
}
