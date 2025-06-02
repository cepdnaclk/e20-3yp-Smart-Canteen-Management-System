package com.SmartCanteen.Backend.DTOs;

import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class ScheduledOrderDTO {
    private Long userId;
    private List<CartItemDTO> items;
    private LocalDateTime scheduledTime;
}
