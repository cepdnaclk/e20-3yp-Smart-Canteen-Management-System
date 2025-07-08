package com.SmartCanteen.Backend.DTOs;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class CustomerResponseDTO {
    private Long id;
    private String username;
    private String email;
    private String fullName;
    private BigDecimal creditBalance;
}
