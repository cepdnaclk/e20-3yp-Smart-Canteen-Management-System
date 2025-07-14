package com.SmartCanteen.Backend.DTOs;

import com.SmartCanteen.Backend.Entities.OrderStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BiometricAuthResponseDTO {
    private boolean authenticated;
    private String message;
    private OrderStatus orderStatus;
}
