package com.SmartCanteen.Backend.DTOs;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class CustomerDTO {
    private Long id;
    private String username;
    private String email;
    private String fullName;
    private BigDecimal creditBalance;
    private String password;
    private String CardID;
    private String FingerprintID;
}
