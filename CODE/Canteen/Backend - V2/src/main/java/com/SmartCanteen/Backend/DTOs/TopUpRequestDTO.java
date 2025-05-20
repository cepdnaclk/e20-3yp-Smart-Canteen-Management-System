package com.SmartCanteen.Backend.DTOs;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class TopUpRequestDTO {
    private BigDecimal amount;
}
