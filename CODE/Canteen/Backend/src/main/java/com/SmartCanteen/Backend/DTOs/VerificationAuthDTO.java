package com.SmartCanteen.Backend.DTOs;

import lombok.Data;
@Data
public class VerificationAuthDTO extends AuthResponseDTO {
    private String email;
    private String code;
}
