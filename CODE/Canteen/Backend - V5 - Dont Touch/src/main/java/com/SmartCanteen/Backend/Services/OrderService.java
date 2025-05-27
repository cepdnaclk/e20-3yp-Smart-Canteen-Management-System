package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.CartItemDTO;
import com.SmartCanteen.Backend.DTOs.OrderDTO;
import com.SmartCanteen.Backend.Entities.Customer;
import com.SmartCanteen.Backend.Entities.MenuItem;
import com.SmartCanteen.Backend.Entities.Order;
import com.SmartCanteen.Backend.Entities.OrderStatus;
import com.SmartCanteen.Backend.Repositories.MenuItemRepository;
import com.SmartCanteen.Backend.Repositories.OrderRepository;
import com.SmartCanteen.Backend.Repositories.CustomerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderRepository orderRepository;
    private final MenuItemRepository menuItemRepository;
    private final CustomerRepository customerRepository;

    public OrderDTO placeOrder(OrderDTO orderDTO) {
        // Calculate total amount
        BigDecimal total = calculateOrderTotal((List<CartItemDTO>) orderDTO.getItems());
        // Create and save order
        Customer customer = customerRepository.findById(orderDTO.getUserId())
                .orElseThrow(() -> new RuntimeException("Customer not found: " + orderDTO.getUserId()));
        Order order = new Order();
        order.setCustomer(customer);
        order.setStatus(OrderStatus.PENDING);
        order.setOrderTime(orderDTO.getOrderTime() != null ? orderDTO.getOrderTime() : LocalDateTime.now());
        order.setScheduledTime(orderDTO.getScheduledTime());
        Map<Long, Integer> itemsMap = orderDTO.getItems();
        order.setItems(itemsMap);
        order.setTotalAmount(total);
        order = orderRepository.save(order);
        // Map to DTO and return
        orderDTO.setId(order.getId());
        orderDTO.setTotalAmount(total);
        orderDTO.setStatus(String.valueOf(order.getStatus()));
        orderDTO.setOrderTime(order.getOrderTime());
        orderDTO.setScheduledTime(order.getScheduledTime());
        return orderDTO;
    }

    private BigDecimal calculateOrderTotal(List<CartItemDTO> items) {
        if (items == null || items.isEmpty()) {
            return BigDecimal.ZERO;
        }
        Set<Long> menuItemIds = items.stream()
                .map(CartItemDTO::getMenuItemId)
                .collect(Collectors.toSet());
        Map<Long, MenuItem> menuItemMap = menuItemRepository.findAllById(menuItemIds)
                .stream()
                .collect(Collectors.toMap(MenuItem::getId, mi -> mi));
        BigDecimal total = BigDecimal.ZERO;
        for (CartItemDTO item : items) {
            MenuItem menuItem = menuItemMap.get(item.getMenuItemId());
            if (menuItem == null) {
                throw new RuntimeException("MenuItem with ID " + item.getMenuItemId() + " not found");
            }
            total = total.add(menuItem.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())));
        }
        return total;
    }

    public BigDecimal calculateOrderValue(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));
        Map<Long, Integer> items = order.getItems();
        if (items == null || items.isEmpty()) {
            return BigDecimal.ZERO;
        }
        Map<Long, MenuItem> menuItemMap = menuItemRepository.findAllById(items.keySet())
                .stream()
                .collect(Collectors.toMap(MenuItem::getId, mi -> mi));
        BigDecimal total = BigDecimal.ZERO;
        for (var entry : items.entrySet()) {
            MenuItem menuItem = menuItemMap.get(entry.getKey());
            if (menuItem == null) {
                throw new RuntimeException("MenuItem with ID " + entry.getKey() + " not found");
            }
            total = total.add(menuItem.getPrice().multiply(BigDecimal.valueOf(entry.getValue())));
        }
        return total;
    }
}
