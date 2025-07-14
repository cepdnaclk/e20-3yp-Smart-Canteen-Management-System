package com.SmartCanteen.Backend.DTOs;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class NotificationDTO {
    private Long id;
    private String message;
    private LocalDateTime timestamp;
    private boolean read;
}
