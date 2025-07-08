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
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;
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

        // Convert List<CartItemDTO> to Map<Long, Integer>
        Map<String, Integer> itemsMap = orderDTO.getItems();

        // Validate stock and calculate total
        BigDecimal total = BigDecimal.ZERO;
        for (var entry : itemsMap.entrySet()) {
            Long menuItemId = Long.valueOf(entry.getKey());
            Integer quantity = entry.getValue();
            MenuItem item = menuItemRepository.findById(menuItemId)
                    .orElseThrow(() -> new RuntimeException("Menu item not found: " + menuItemId));
            if (item.getStock() < quantity) {
                throw new RuntimeException("Insufficient stock for item: " + item.getName());
            }
            total = total.add(item.getPrice().multiply(BigDecimal.valueOf(quantity)));
        }

        // Check customer balance
        if (customer.getCreditBalance().compareTo(total) < 0) {
            throw new RuntimeException("Insufficient credit balance");
        }

        // Deduct stock and balance
        for (var entry : itemsMap.entrySet()) {
            Long menuItemId = Long.valueOf(entry.getKey());
            Integer quantity = entry.getValue();
            MenuItem item = menuItemRepository.findById(menuItemId).orElseThrow();
            item.setStock(item.getStock() - quantity);
            menuItemRepository.save(item);
        }

        customer.setCreditBalance(customer.getCreditBalance().subtract(total));
        customerRepository.save(customer);

        // Save order
        Order order = new Order();
        order.setCustomer(customer);
        order.setItems(itemsMap);
        order.setTotalAmount(total);
        order.setStatus(OrderStatus.PENDING);
        order.setOrderTime(orderDTO.getOrderTime() != null ? orderDTO.getOrderTime() : LocalDateTime.now());
        order.setScheduledTime(orderDTO.getScheduledTime());

        order = orderRepository.save(order);

        // Notify customer
        notificationService.sendNotification(customer, "Order placed successfully. Order ID: " + order.getId());

        // Map back to DTO
        OrderDTO result = modelMapper.map(order, OrderDTO.class);
        // If you want to keep List<CartItemDTO> in the result, you can set it here
        // result.setItems(orderDTO.getItems());
        return result;
    }


    public List<OrderDTO> getOrderHistory() {
        Customer customer = getCurrentAuthenticatedCustomer();
        List<Order> orders = orderRepository.findByCustomer(customer);
        return orders.stream()
                .map(order -> modelMapper.map(order, OrderDTO.class))
                .collect(Collectors.toList());
    }

    public BigDecimal getCreditBalance(Long userId) {
        Customer customer = getCurrentAuthenticatedCustomer();
        // Optionally, validate that the authenticated user matches the userId if needed
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


    @Transactional
    public OrderDTO placeOrderAsSystem(OrderDTO orderDTO, Long userId) {
        Customer customer = customerRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Customer not found: " + userId));

        Map<String, Integer> itemsMap = orderDTO.getItems();
        if (itemsMap == null || itemsMap.isEmpty()) {
            throw new IllegalArgumentException("Order items cannot be empty");
        }

        Set<Long> menuItemIds = itemsMap.keySet().stream()
                .map(Long::valueOf)
                .collect(Collectors.toSet());

        Map<Long, MenuItem> menuItemMap = menuItemRepository.findAllById(menuItemIds)
                .stream().collect(Collectors.toMap(MenuItem::getId, mi -> mi));

        BigDecimal total = BigDecimal.ZERO;
        for (Map.Entry<String, Integer> entry : itemsMap.entrySet()) {
            MenuItem menuItem = menuItemMap.get(entry.getKey());
            if (menuItem == null) {
                throw new RuntimeException("MenuItem with ID " + entry.getKey() + " not found");
            }
            total = total.add(menuItem.getPrice().multiply(BigDecimal.valueOf(entry.getValue())));
        }

        Order order = new Order();
        order.setCustomer(customer);
        order.setStatus(OrderStatus.PENDING);
        order.setOrderTime(LocalDateTime.now());
        order.setScheduledTime(orderDTO.getScheduledTime());
        order.setItems(itemsMap);
        order.setTotalAmount(total);

        order = orderRepository.save(order);

        OrderDTO result = new OrderDTO();
        result.setId(order.getId());
        result.setEmail(customer.getEmail());
        result.setItems(itemsMap);
        result.setTotalAmount(total);
        result.setStatus(order.getStatus().name());
        result.setOrderTime(order.getOrderTime());
        result.setScheduledTime(order.getScheduledTime());
        return result;
    }
    public CustomerResponseDTO getProfileById(String cardid) {
        Customer customer = customerRepository.findByCardID(cardid)
                .orElseThrow(() -> new RuntimeException("Customer not found with RFID: " + cardid));
        return modelMapper.map(customer, CustomerResponseDTO.class);
    }
    //manuja
    public FingerprintResponseDto getFingerprintByEmail(String email) {
        Customer customer = customerRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Customer not found"));
        return new FingerprintResponseDto(customer.getEmail(), customer.getFingerprintID());
    }
}

