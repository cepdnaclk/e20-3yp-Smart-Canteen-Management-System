package com.SmartCanteen.Backend.DTOs;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class SendMessageDTO {
    @NotNull
    private Long recipientId;
    @NotBlank
    private String content;
}