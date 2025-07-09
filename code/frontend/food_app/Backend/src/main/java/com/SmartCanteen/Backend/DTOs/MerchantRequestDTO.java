package com.SmartCanteen.Backend.DTOs;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class MerchantRequestDTO {
    @NotBlank(message = "Username is required")
    private String username;

    @NotBlank(message = "Canteen name is required")
    private String canteenName;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 6, message = "Password must be at least 6 characters")
    private String password;



//    private String password;
//    private String email;
//    private String fullName;
//    private String CanteenName;
    private String cardID;
    private String fingerprintID;
}
