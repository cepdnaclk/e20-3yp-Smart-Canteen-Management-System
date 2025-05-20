package com.SmartCanteen.Backend.DTOs;

import lombok.Data;

@Data
public class MerchantRequestDTO {
    private String username;
    private String email;
    private String fullName;
    private String password;
    private String cardID;
    private String fingerprintID;
}
