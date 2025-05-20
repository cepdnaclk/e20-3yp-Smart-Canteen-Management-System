package com.SmartCanteen.Backend.DTOs;

import lombok.Data;

@Data
public class AdminResponseDTO {
    private Long id;
    private String username;
    private String email;
    private String fullName;
    // No password or sensitive info here
}
