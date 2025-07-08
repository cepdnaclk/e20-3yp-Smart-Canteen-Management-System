package com.SmartCanteen.Backend.DTOs;

import com.SmartCanteen.Backend.Entities.OrderStatus;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderCompletionDTO {
    private boolean success;
    private String message;
    private OrderStatus status;
}
