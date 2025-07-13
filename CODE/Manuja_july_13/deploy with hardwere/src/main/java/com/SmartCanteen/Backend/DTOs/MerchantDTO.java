package com.SmartCanteen.Backend.DTOs;

import lombok.Data;

@Data
public class MerchantDTO {
    private Long id;
    private String username;
    private String email;
    private String fullName;
    private String password;
    private String CardID;
    private String FingerprintID;
}
