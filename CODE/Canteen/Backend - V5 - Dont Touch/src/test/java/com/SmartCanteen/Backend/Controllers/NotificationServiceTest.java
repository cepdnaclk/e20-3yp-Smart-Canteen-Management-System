package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.Services.NotificationService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.math.BigDecimal;

@SpringBootTest
public class NotificationServiceTest {
    @Autowired
    private NotificationService notificationService;

    @Test
    void sendPaymentNotification_ShouldPrintMessage() {
        notificationService.sendPaymentNotification(1L, BigDecimal.TEN, BigDecimal.valueOf(90));
        // Check logs or mock output as needed
    }
}