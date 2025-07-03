package com.SmartCanteen.Backend.DTOs;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class VerifyEmailRequestDTO {
    @NotBlank
    @Email
    private String email;

    private String code;
}
