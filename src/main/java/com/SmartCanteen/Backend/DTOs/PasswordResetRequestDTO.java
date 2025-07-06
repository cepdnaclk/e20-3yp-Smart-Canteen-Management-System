package com.SmartCanteen.Backend.DTOs;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class PasswordResetRequestDTO {
    @NotBlank
    private String token;

    @NotBlank
    private String newPassword;
}