package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.Entities.MenuItem;
import com.SmartCanteen.Backend.Entities.Merchant;
import com.SmartCanteen.Backend.Repositories.MenuItemRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class StockAlertService {

    private static final Logger log = LoggerFactory.getLogger(StockAlertService.class);
    private static final int LOW_STOCK_THRESHOLD = 10;

    private final MenuItemRepository menuItemRepository;
    private final NotificationService notificationService;

    // Runs every 4 hours. Cron expression: (seconds minutes hours day-of-month month day-of-week)
    @Scheduled(cron = "0 0 */4 * * *")
    public void checkForLowStock() {
        log.info("Running scheduled job: Checking for low stock items...");
        List<MenuItem> lowStockItems = menuItemRepository.findByStockLessThan(LOW_STOCK_THRESHOLD);

        if (lowStockItems.isEmpty()) {
            log.info("No low stock items found.");
            return;
        }

        log.info("Found {} low stock items. Sending notifications...", lowStockItems.size());
        for (MenuItem item : lowStockItems) {
            try {
                Merchant merchant = item.getCategory().getMerchant();
                if (merchant != null) {
                    String message = String.format(
                            "Stock Alert: '%s' is running low. Current stock: %d.",
                            item.getName(),
                            item.getStock()
                    );
                    notificationService.sendNotification(merchant, message);
                }
            } catch (Exception e) {
                log.error("Failed to send notification for low stock item ID: {}", item.getId(), e);
            }
        }
        log.info("Finished sending low stock notifications.");
    }
}