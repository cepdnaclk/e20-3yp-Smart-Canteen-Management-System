package com.SmartCanteen.Backend.DTOs;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CustomerBiometricSaveDTO {

    @NotBlank
    @Email
    private String email;

    @NotBlank
    private String cardID;

    @NotBlank
    private String fingerprintID;
}
