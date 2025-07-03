package com.SmartCanteen.Backend.Config;

import com.SmartCanteen.Backend.Entities.Order;
import com.SmartCanteen.Backend.Entities.ScheduledOrder;
import com.SmartCanteen.Backend.Repositories.ScheduledOrderRepository;
import com.SmartCanteen.Backend.Services.CustomerService;
import com.SmartCanteen.Backend.Services.NotificationService;
import com.SmartCanteen.Backend.Services.OrderService; // Import OrderService
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Configuration
@EnableScheduling
@RequiredArgsConstructor
public class ScheduledOrderConfig {

    private static final Logger log = LoggerFactory.getLogger(ScheduledOrderConfig.class);

    private final ScheduledOrderRepository scheduledOrderRepository;
    private final OrderService orderService; // Correctly inject OrderService
    private final CustomerService customerService; // Still needed for getCreditBalance
    private final NotificationService notificationService;

    @Scheduled(fixedRate = 60000) // Runs every minute
    public void processScheduledOrders() {
        LocalDateTime now = LocalDateTime.now();
        List<ScheduledOrder> ordersToProcess = scheduledOrderRepository.findByScheduledTimeBeforeAndProcessedFalse(now);

        if (!ordersToProcess.isEmpty()) {
            log.info("Found {} scheduled orders to process.", ordersToProcess.size());
        }

        for (ScheduledOrder scheduledOrder : ordersToProcess) {
            try {
                // The call is now correctly directed to OrderService
                Order placedOrder = orderService.createOrderFromScheduledOrder(scheduledOrder);

                scheduledOrder.setProcessed(true);
                scheduledOrderRepository.save(scheduledOrder);

                // Notify user of success
                BigDecimal newBalance = customerService.getCreditBalance(scheduledOrder.getUserId());
                String message = String.format("Your scheduled order #%d has been placed successfully. Your new balance is ₹%.2f",
                        placedOrder.getId(), newBalance);
                notificationService.sendNotification(placedOrder.getCustomer(), message);

            } catch (Exception ex) {
                log.error("Failed to process scheduled order {}: {}", scheduledOrder.getId(), ex.getMessage());
                // Mark as processed to prevent retrying a permanently failing order (e.g. deleted item)
                // A more advanced system might have a retry count or a 'failed' status.
                scheduledOrder.setProcessed(true);
                scheduledOrderRepository.save(scheduledOrder);
            }
        }
    }
}