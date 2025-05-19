package com.SmartCanteen.Backend.DTOs;

import lombok.Data;

@Data
public class AuthResponseDTO {
    private String token;
    private String tokenType = "Bearer";
    private Long userId;
    private String username;
    private String role;
}
