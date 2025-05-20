package com.SmartCanteen.Backend.DTOs;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class CustomerRequestDTO {
    private String username;
    private String email;
    private String fullName;
    private String password;
    private String cardID;
    private String fingerprintID;
    private BigDecimal creditBalance; // Optional: usually starts at zero
}
