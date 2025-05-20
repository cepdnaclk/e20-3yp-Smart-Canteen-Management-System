package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.Entities.Notification;
import com.SmartCanteen.Backend.Entities.User;
import com.SmartCanteen.Backend.Repositories.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;

    public void sendNotification(User recipient, String message) {
        Notification notification = new Notification();
        notification.setRecipient(recipient);
        notification.setMessage(message);
        notification.setTimestamp(LocalDateTime.now());
        notification.setRead(false);
        notificationRepository.save(notification);
    }

    public List<Notification> getNotificationsForCurrentUser() {
        User user = getCurrentUser();
        return notificationRepository.findByRecipientOrderByTimestampDesc(user);
    }

    public void markNotificationAsRead(Long notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));
        notification.setRead(true);
        notificationRepository.save(notification);
    }

    private User getCurrentUser() {
        // Implement retrieval from security context
        throw new UnsupportedOperationException("Implement security context user retrieval");
    }
}
