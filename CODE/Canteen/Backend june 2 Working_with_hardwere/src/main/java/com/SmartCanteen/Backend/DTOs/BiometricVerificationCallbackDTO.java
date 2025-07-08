package com.SmartCanteen.Backend.DTOs;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
public class BiometricVerificationCallbackDTO {
    private String email;
    private Long orderId;
    private String token;
    private double confidence;
    private String scannedId;
    private String esp32Ip;


}
