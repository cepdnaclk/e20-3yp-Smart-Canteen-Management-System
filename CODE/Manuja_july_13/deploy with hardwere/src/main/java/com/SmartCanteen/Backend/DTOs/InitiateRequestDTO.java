// InitiateRequestDTO.java
package com.SmartCanteen.Backend.DTOs;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotNull;
import lombok.*;


@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InitiateRequestDTO {
    @Email
    private String email;

    @NotNull
    private Long orderId;
}


