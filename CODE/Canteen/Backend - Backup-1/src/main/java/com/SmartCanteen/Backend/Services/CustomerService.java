package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.*;
import com.SmartCanteen.Backend.Entities.*;
import com.SmartCanteen.Backend.Repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CustomerService {

    private final CustomerRepository customerRepository;
    private final OrderRepository orderRepository;
    private final MenuItemRepository menuItemRepository;
    private final NotificationService notificationService;

    // Example method to get customer profile (assuming security context provides current user)
    public CustomerResponseDTO getProfile() {
        Customer customer = getCurrentCustomer();
        return mapToDTO(customer);
    }

    public List<MenuItemDTO> getMenuItems() {
        return menuItemRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public OrderDTO placeOrder(OrderDTO orderDTO) {
        Customer customer = getCurrentCustomer();

        // Validate stock and calculate total amount
        BigDecimal total = BigDecimal.ZERO;
        for (var entry : orderDTO.getItems().entrySet()) {
            MenuItem item = menuItemRepository.findById(entry.getKey())
                    .orElseThrow(() -> new RuntimeException("Menu item not found"));
            if (item.getStock() < entry.getValue()) {
                throw new RuntimeException("Insufficient stock for item: " + item.getName());
            }
            total = total.add(item.getPrice().multiply(BigDecimal.valueOf(entry.getValue())));
        }

        if (customer.getCreditBalance().compareTo(total) < 0) {
            throw new RuntimeException("Insufficient credit balance");
        }

        // Deduct stock and balance
        for (var entry : orderDTO.getItems().entrySet()) {
            MenuItem item = menuItemRepository.findById(entry.getKey()).get();
            item.setStock(item.getStock() - entry.getValue());
            menuItemRepository.save(item);
        }

        customer.setCreditBalance(customer.getCreditBalance().subtract(total));
        customerRepository.save(customer);

        // Save order
        Order order = new Order();
        order.setCustomer(customer);
        order.setItems(orderDTO.getItems());
        order.setTotalAmount(total);
        order.setStatus(OrderStatus.PENDING);
        order.setOrderTime(orderDTO.getOrderTime() != null ? orderDTO.getOrderTime() : java.time.LocalDateTime.now());
        order.setScheduledTime(orderDTO.getScheduledTime());

        order = orderRepository.save(order);

        // Notify customer
        notificationService.sendNotification(customer, "Order placed successfully. Order ID: " + order.getId());

        // Map and return
        return mapOrderToDTO(order);
    }

    public List<OrderDTO> getOrderHistory() {
        Customer customer = getCurrentCustomer();
        List<Order> orders = orderRepository.findByCustomer(customer);
        return orders.stream().map(this::mapOrderToDTO).collect(Collectors.toList());
    }

    public BigDecimal getCreditBalance() {
        Customer customer = getCurrentCustomer();
        return customer.getCreditBalance();
    }

    // Helper methods

    private Customer getCurrentCustomer() {
        // Implement retrieval of current logged-in customer from SecurityContext
        // For example:
        // String username = SecurityContextHolder.getContext().getAuthentication().getName();
        // return customerRepository.findByUsername(username).orElseThrow(...);
        throw new UnsupportedOperationException("Implement security context user retrieval");
    }

    private CustomerResponseDTO mapToDTO(Customer customer) {
        CustomerResponseDTO dto = new CustomerResponseDTO();
        dto.setId(customer.getId());
        dto.setUsername(customer.getUsername());
        dto.setEmail(customer.getEmail());
        dto.setFullName(customer.getFullName());
        dto.setCreditBalance(customer.getCreditBalance());
        return dto;
    }

    private MenuItemDTO mapToDTO(MenuItem item) {
        MenuItemDTO dto = new MenuItemDTO();
        dto.setId(item.getId());
        dto.setName(item.getName());
        dto.setCategoryId(item.getCategory().getId());
        dto.setCategoryName(item.getCategory().getName());
        dto.setPrice(item.getPrice());
        dto.setStock(item.getStock());
        return dto;
    }


    private OrderDTO mapOrderToDTO(Order order) {
        OrderDTO dto = new OrderDTO();
        dto.setId(order.getId());
        dto.setCustomerId(order.getCustomer().getId());
        dto.setItems(order.getItems());
        dto.setTotalAmount(order.getTotalAmount());
        dto.setStatus(order.getStatus().name());
        dto.setOrderTime(order.getOrderTime());
        dto.setScheduledTime(order.getScheduledTime());
        return dto;
    }
}
