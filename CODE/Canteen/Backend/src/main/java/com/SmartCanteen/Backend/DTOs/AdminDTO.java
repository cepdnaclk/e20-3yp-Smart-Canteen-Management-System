package com.SmartCanteen.Backend.DTOs;

import lombok.Data;

@Data
public class AdminDTO {
    private Long id;
    private String username;
    private String email;
    private String fullName;
    private String password;
    private String CardID;
    private String FingerprintID;
}
