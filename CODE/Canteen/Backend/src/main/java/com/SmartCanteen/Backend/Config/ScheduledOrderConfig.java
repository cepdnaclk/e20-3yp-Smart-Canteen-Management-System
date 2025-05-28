package com.SmartCanteen.Backend.Config;

import com.SmartCanteen.Backend.DTOs.OrderDTO;
import com.SmartCanteen.Backend.Entities.ScheduledOrder;
import com.SmartCanteen.Backend.Repositories.ScheduledOrderRepository;
import com.SmartCanteen.Backend.Services.CustomerService;
import com.SmartCanteen.Backend.Services.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Configuration
@EnableScheduling
@RequiredArgsConstructor
public class ScheduledOrderConfig {
    private final ScheduledOrderRepository scheduledOrderRepository;
    private final CustomerService customerService;
    private final NotificationService notificationService;

    @Scheduled(fixedRate = 60000)
    public void processScheduledOrders() {
        LocalDateTime now = LocalDateTime.now();
        List<ScheduledOrder> orders = scheduledOrderRepository.findByScheduledTimeBeforeAndProcessedFalse(now);
        for (ScheduledOrder order : orders) {
            try {
                OrderDTO orderDTO = new OrderDTO();
                orderDTO.setUserId(order.getUserId());
                orderDTO.setItems(order.getItems().stream()
                        .collect(Collectors.toMap(
                                item -> item.getMenuItemId(),
                                item -> item.getQuantity()
                        )));
                orderDTO.setScheduledTime(order.getScheduledTime());

                // This will throw if customer doesn't exist
                OrderDTO placedOrder = customerService.placeOrderAsSystem(orderDTO, order.getUserId());

                order.setProcessed(true);
                scheduledOrderRepository.save(order);

                BigDecimal newBalance = customerService.getCreditBalance(order.getUserId());
                notificationService.sendOrderNotification(order.getUserId(), placedOrder, newBalance);
            } catch (RuntimeException ex) {
                // Log and skip this order, do not mark as processed
                System.err.println("Scheduled order " + order.getId() + " failed: " + ex.getMessage());
                // Optionally: Add a retry count or failure reason to the order entity
            }
        }
    }
}
