package com.SmartCanteen.Backend.DTOs;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class MerchantRequestDTO {

    @NotBlank(message = "Username is required")
    private String username;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Canteen name is required")
    private String fullName;

    @NotBlank(message = "Password is required")
    private String password;

    private String cardID;

    private String fingerprintID;


    private Double creditBalance;
}
