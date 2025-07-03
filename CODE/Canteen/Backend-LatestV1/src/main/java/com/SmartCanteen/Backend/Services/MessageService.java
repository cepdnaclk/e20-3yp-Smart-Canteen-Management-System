package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.MessageDTO;
import com.SmartCanteen.Backend.DTOs.SendMessageDTO;
import com.SmartCanteen.Backend.Entities.Message;
import com.SmartCanteen.Backend.Entities.User;
import com.SmartCanteen.Backend.Exceptions.ResourceNotFoundException;
import com.SmartCanteen.Backend.Repositories.MessageRepository;
import com.SmartCanteen.Backend.Repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MessageService {

    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final ModelMapper modelMapper;

    @Transactional
    public MessageDTO sendMessage(SendMessageDTO sendMessageDTO) {
        String currentPrincipalName = SecurityContextHolder.getContext().getAuthentication().getName();
        User sender = userRepository.findByEmail(currentPrincipalName)
                .orElseThrow(() -> new ResourceNotFoundException("Sender not found"));
        User recipient = userRepository.findById(sendMessageDTO.getRecipientId())
                .orElseThrow(() -> new ResourceNotFoundException("Recipient not found"));

        Message message = new Message();
        message.setSender(sender);
        message.setRecipient(recipient);
        message.setContent(sendMessageDTO.getContent());

        Message savedMessage = messageRepository.save(message);
        return modelMapper.map(savedMessage, MessageDTO.class);
    }

    @Transactional(readOnly = true)
    public List<MessageDTO> getConversation(Long otherUserId) {
        String currentPrincipalName = SecurityContextHolder.getContext().getAuthentication().getName();
        User currentUser = userRepository.findByEmail(currentPrincipalName)
                .orElseThrow(() -> new ResourceNotFoundException("Current user not found"));

        List<Message> messages = messageRepository.findConversation(currentUser.getId(), otherUserId);
        return messages.stream()
                .map(message -> modelMapper.map(message, MessageDTO.class))
                .collect(Collectors.toList());
    }
}