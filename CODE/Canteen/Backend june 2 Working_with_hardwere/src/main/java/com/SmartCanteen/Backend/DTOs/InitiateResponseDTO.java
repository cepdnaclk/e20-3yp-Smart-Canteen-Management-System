package com.SmartCanteen.Backend.DTOs;

import lombok.*;

@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class InitiateResponseDTO {

    private boolean initiated;
    private String message;
}
