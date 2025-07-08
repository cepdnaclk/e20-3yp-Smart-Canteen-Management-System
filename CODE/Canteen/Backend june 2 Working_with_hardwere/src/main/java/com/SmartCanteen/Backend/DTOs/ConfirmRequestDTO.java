package com.SmartCanteen.Backend.DTOs;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;

@Getter
@Setter
@NoArgsConstructor
public class ConfirmRequestDTO {

    private String email;
    private Long orderId;
    private int confidence;
    private String scannedId;
}
