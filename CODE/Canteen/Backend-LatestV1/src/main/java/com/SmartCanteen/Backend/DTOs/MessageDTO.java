package com.SmartCanteen.Backend.DTOs;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class MessageDTO {
    private Long id;
    private Long senderId;
    private String senderUsername;
    private Long recipientId;
    private String recipientUsername;
    private String content;
    private LocalDateTime timestamp;
    private boolean isRead;
}