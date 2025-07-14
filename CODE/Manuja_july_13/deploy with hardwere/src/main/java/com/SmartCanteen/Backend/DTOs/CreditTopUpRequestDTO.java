package com.SmartCanteen.Backend.DTOs;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class CreditTopUpRequestDTO {
    private Long id;
    private Long customerId;
    private Long merchantId;
    private BigDecimal amount;
    private String status;
    private String pin;
    private LocalDateTime requestTime;
    private LocalDateTime responseTime;
}

