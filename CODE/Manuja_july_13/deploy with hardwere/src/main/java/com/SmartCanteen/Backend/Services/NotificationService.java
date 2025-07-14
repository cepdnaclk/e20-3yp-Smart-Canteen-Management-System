package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.OrderDTO;
import com.SmartCanteen.Backend.Entities.Notification;
import com.SmartCanteen.Backend.Entities.User;
import com.SmartCanteen.Backend.Repositories.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private JavaMailSender mailSender;

    public void sendNotification(User recipient, String message) {
        Notification notification = new Notification();
        notification.setRecipient(recipient);
        notification.setMessage(message);
        notification.setTimestamp(LocalDateTime.now());
        notification.setReading(false);
        notificationRepository.save(notification);
    }


    public List<Notification> getNotificationsForCurrentUser() {
        User user = getCurrentUser();
        Pageable pageable = PageRequest.of(0, 20); // first page, 20 items per page
        return notificationRepository.findByRecipientOrderByTimestampDesc(user, pageable).getContent();
    }


    public void markNotificationAsRead(Long notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));
        notification.setReading(true);
        notificationRepository.save(notification);
    }

    private User getCurrentUser() {
        // Implement retrieval from security context
        throw new UnsupportedOperationException("Implement security context user retrieval");
    }

    public void sendOrderNotification(Long userId, OrderDTO order, BigDecimal newBalance) {
        String message = String.format("Order %d placed by user %d. New balance: %s", order.getId(), userId, newBalance);
        System.out.println(message);
        // If you want to save to DB, implement getCurrentUser and use sendNotification

    }

    public void sendPaymentNotification(Long userId, BigDecimal amount, BigDecimal newBalance) {
        String message = String.format("User %d paid %s. New balance: %s", userId, amount, newBalance);
        System.out.println(message);
        // sendNotification(currentUser, message);
    }

    public void sendScheduledOrderNotification(Long userId, String scheduledTime) {
        System.out.printf("User %d scheduled an order for %s%n", userId, scheduledTime);
    }

    public void sendEmail(String to, String subject, String body) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(to);
        message.setSubject(subject);
        message.setText(body);
        mailSender.send(message);
    }
}
