package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.*;
import com.SmartCanteen.Backend.Entities.*;
import com.SmartCanteen.Backend.Repositories.*;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import jakarta.transaction.Transactional;
import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class CustomerService {

    private final CustomerRepository customerRepository;
    private final OrderRepository orderRepository;
    private final MenuItemRepository menuItemRepository;
    private final NotificationService notificationService;
    private final ModelMapper modelMapper;

    public CustomerResponseDTO getProfile() {
        Customer customer = getCurrentAuthenticatedCustomer();
        return modelMapper.map(customer, CustomerResponseDTO.class);
    }

    public List<MenuItemDTO> getMenuItems() {
        return menuItemRepository.findAll().stream()
                .map(item -> modelMapper.map(item, MenuItemDTO.class))
                .collect(Collectors.toList());
    }

    public OrderDTO placeOrder(OrderDTO orderDTO) {
        Customer customer = getCurrentAuthenticatedCustomer();

        // Validate stock and calculate total
        BigDecimal total = BigDecimal.ZERO;
        for (var entry : orderDTO.getItems().entrySet()) {
            MenuItem item = menuItemRepository.findById(entry.getKey())
                    .orElseThrow(() -> new RuntimeException("Menu item not found: " + entry.getKey()));
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

        return modelMapper.map(order, OrderDTO.class);
    }

    public List<OrderDTO> getOrderHistory() {
        Customer customer = getCurrentAuthenticatedCustomer();
        List<Order> orders = orderRepository.findByCustomer(customer);
        return orders.stream()
                .map(order -> modelMapper.map(order, OrderDTO.class))
                .collect(Collectors.toList());
    }

    public BigDecimal getCreditBalance() {
        Customer customer = getCurrentAuthenticatedCustomer();
        return customer.getCreditBalance();
    }

    public CustomerResponseDTO updateProfile(CustomerUpdateDTO updateDTO) {
        Customer customer = getCurrentAuthenticatedCustomer();


        customer.setEmail(updateDTO.getEmail());
        customer.setFullName(updateDTO.getFullName());
        customer.setCardID(updateDTO.getCardID());
        customer.setFingerprintID(updateDTO.getFingerprintID());

        customerRepository.save(customer);

        return modelMapper.map(customer, CustomerResponseDTO.class);
    }

    public void deleteCurrentCustomer() {
        Customer customer = getCurrentAuthenticatedCustomer();
        customerRepository.delete(customer);
    }

    public Customer getCurrentAuthenticatedCustomer() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || !authentication.isAuthenticated()) {
            throw new UsernameNotFoundException("No authenticated user found");
        }

        String username = authentication.getName();

        return customerRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("Customer not found with username: " + username));
    }
}
