package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.MessageDTO;
import com.SmartCanteen.Backend.DTOs.SendMessageDTO;
import com.SmartCanteen.Backend.Services.MessageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/messages")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()") // Secure all message endpoints
public class MessageController {

    private final MessageService messageService;

    @PostMapping("/send")
    public ResponseEntity<MessageDTO> sendMessage(@Valid @RequestBody SendMessageDTO sendMessageDTO) {
        MessageDTO message = messageService.sendMessage(sendMessageDTO);
        return ResponseEntity.ok(message);
    }

    @GetMapping("/conversation/{otherUserId}")
    public ResponseEntity<List<MessageDTO>> getConversation(@PathVariable Long otherUserId) {
        List<MessageDTO> conversation = messageService.getConversation(otherUserId);
        return ResponseEntity.ok(conversation);
    }
}