package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.Entities.MenuItem;
import com.SmartCanteen.Backend.Entities.Order;
import com.SmartCanteen.Backend.Repositories.MenuItemRepository;
import com.SmartCanteen.Backend.Repositories.OrderRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final MenuItemRepository menuItemRepository;

    public BigDecimal calculateOrderValue(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        Map<Long, Integer> items = order.getItems(); // Map<MenuItemId, Quantity>
        if (items == null || items.isEmpty()) {
            return BigDecimal.ZERO;
        }

        Set<Long> menuItemIds = items.keySet();

        // Fetch all MenuItems for the IDs in the order
        List<MenuItem> menuItems = menuItemRepository.findAllById(menuItemIds);

        // Map MenuItem ID to MenuItem for quick lookup
        Map<Long, MenuItem> menuItemMap = menuItems.stream()
                .collect(Collectors.toMap(MenuItem::getId, mi -> mi));

        // Calculate total
        BigDecimal total = BigDecimal.ZERO;
        for (Map.Entry<Long, Integer> entry : items.entrySet()) {
            Long menuItemId = entry.getKey();
            Integer quantity = entry.getValue();

            MenuItem menuItem = menuItemMap.get(menuItemId);
            if (menuItem == null) {
                throw new RuntimeException("MenuItem with ID " + menuItemId + " not found");
            }

            BigDecimal price = menuItem.getPrice();
            total = total.add(price.multiply(BigDecimal.valueOf(quantity)));
        }

        return total;
    }
}
