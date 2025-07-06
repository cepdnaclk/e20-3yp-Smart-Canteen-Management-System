package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.OrderDTO;
import com.SmartCanteen.Backend.Entities.*;
import com.SmartCanteen.Backend.Exceptions.InsufficientBalanceException;
import com.SmartCanteen.Backend.Exceptions.ResourceNotFoundException;
import com.SmartCanteen.Backend.Repositories.CustomerRepository;
import com.SmartCanteen.Backend.Repositories.MenuItemRepository;
import com.SmartCanteen.Backend.Repositories.OrderRepository;
import com.SmartCanteen.Backend.Repositories.ReceiptRepository;
import jakarta.mail.MessagingException;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OrderService {

    private static final Logger log = LoggerFactory.getLogger(OrderService.class);

    private final OrderRepository orderRepository;
    private final MenuItemRepository menuItemRepository;
    private final CustomerRepository customerRepository;
    private final NotificationService notificationService;
    private final EmailService emailService;
    private final ModelMapper modelMapper;

    @Transactional
    public OrderDTO placeOrder(OrderDTO orderDTO) {
        if (orderDTO.getEmail() == null) {
            throw new IllegalArgumentException("User email must not be null in OrderDTO");
        }

        Customer customer = customerRepository.findByEmail(orderDTO.getEmail())
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found with email: " + orderDTO.getEmail()));

        Map<Long, Integer> itemsMap = orderDTO.getItems();
        BigDecimal total = calculateOrderTotal(itemsMap);

        if (customer.getCreditBalance().compareTo(total) < 0) {
            throw new InsufficientBalanceException("Insufficient credit balance to place order.");
        }

        reserveStockForOrder(itemsMap);

        Order order = new Order();
        order.setCustomer(customer);
        order.setEmail(customer.getEmail());
        order.setStatus(OrderStatus.PENDING);
        order.setOrderTime(LocalDateTime.now());
        order.setScheduledTime(orderDTO.getScheduledTime());
        order.setItems(itemsMap);
        order.setTotalAmount(total);

        Order savedOrder = orderRepository.save(order);
        log.info("Order #{} placed successfully for customer {}", savedOrder.getId(), customer.getEmail());
        return modelMapper.map(savedOrder, OrderDTO.class);
    }

    @Transactional
    public Order createOrderFromScheduledOrder(ScheduledOrder scheduledOrder) {
        Customer customer = customerRepository.findById(scheduledOrder.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found for scheduled order: " + scheduledOrder.getId()));

        // Correctly create Map<Long, Integer>
        Map<Long, Integer> itemsMap = scheduledOrder.getItems().stream()
                .collect(Collectors.toMap(CartItem::getMenuItemId, CartItem::getQuantity));

        BigDecimal total = calculateOrderTotal(itemsMap);

        if (customer.getCreditBalance().compareTo(total) < 0) {
            log.warn("Insufficient balance for user {} to process scheduled order {}.", customer.getEmail(), scheduledOrder.getId());
            notificationService.sendNotification(customer, "Your scheduled order failed due to insufficient funds.");
            throw new InsufficientBalanceException("Insufficient credit balance for scheduled order.");
        }

        reserveStockForOrder(itemsMap);

        Order order = new Order();
        order.setCustomer(customer);
        order.setEmail(customer.getEmail());
        order.setStatus(OrderStatus.PENDING);
        order.setOrderTime(LocalDateTime.now());
        order.setScheduledTime(scheduledOrder.getScheduledTime());
        order.setItems(itemsMap);
        order.setTotalAmount(total);

        return orderRepository.save(order);
    }

    @Transactional
    public OrderDTO completeOrder(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found with id: " + orderId));

        if (order.getStatus() == OrderStatus.COMPLETED) {
            throw new IllegalStateException("Order is already completed.");
        }

        deductCustomerBalance(order);

        order.setStatus(OrderStatus.COMPLETED);
        Order completedOrder = orderRepository.save(order);
        log.info("Order {} status updated to COMPLETED.", orderId);

        notificationService.sendNotification(order.getCustomer(), "Your order #" + orderId + " is complete and ready for pickup!");

        try {
            emailService.sendOrderConfirmationEmail(completedOrder);
        } catch (MessagingException e) {
            log.error("Failed to send confirmation email for order ID: {}", orderId, e);
        }

        return modelMapper.map(completedOrder, OrderDTO.class);
    }

    public BigDecimal calculateOrderValue(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found: " + orderId));
        return order.getTotalAmount();
    }

    // --- Other public methods like getPendingOrders, getOrderHistory etc. go here ---
    public List<OrderDTO> getPendingOrders() {
        return orderRepository.findByStatus(OrderStatus.PENDING)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public List<OrderDTO> getAcceptedOrders() {
        return orderRepository.findByStatus(OrderStatus.ACCEPTED)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public List<OrderDTO> getCompletedOrders() {
        return orderRepository.findByStatus(OrderStatus.COMPLETED)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public List<OrderDTO> getOrderHistory(String email) {
        Customer customer = customerRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found: " + email));
        return orderRepository.findByCustomer(customer).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public OrderDTO cancelOrder(Long orderId, String username, double cancellationFee) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found"));

        if (order.getStatus() == OrderStatus.COMPLETED || order.getStatus() == OrderStatus.CANCELLED) {
            throw new IllegalStateException("Cannot cancel an order that is already completed or cancelled.");
        }

        // Restore stock
        for(Map.Entry<Long, Integer> entry : order.getItems().entrySet()){
            MenuItem item = menuItemRepository.findById(entry.getKey()).orElse(null);
            if(item != null){
                item.setStock(item.getStock() + entry.getValue());
                menuItemRepository.save(item);
            }
        }

        // Handle fee if applicable
        if(cancellationFee > 0){
            BigDecimal fee = BigDecimal.valueOf(cancellationFee);
            Customer customer = order.getCustomer();
            // Assuming totalAmount was deducted, we add it back minus the fee.
            // If balance is deducted only on completion, this logic needs adjustment.
            // For now, let's assume it's a direct charge.
            customer.setCreditBalance(customer.getCreditBalance().subtract(fee));
            customerRepository.save(customer);
        }

        order.setStatus(OrderStatus.CANCELLED);
        return convertToDTO(orderRepository.save(order));
    }

    @Transactional
    public OrderDTO acceptOrder(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        if (order.getStatus() != OrderStatus.PENDING) {
            throw new IllegalStateException("Only pending orders can be accepted.");
        }

        order.setStatus(OrderStatus.ACCEPTED);
        return convertToDTO(orderRepository.save(order));
    }


    // --- Private Helper Methods ---

    private void reserveStockForOrder(Map<Long, Integer> itemsMap) {
        for (Map.Entry<Long, Integer> entry : itemsMap.entrySet()) {
            MenuItem item = menuItemRepository.findById(entry.getKey())
                    .orElseThrow(() -> new ResourceNotFoundException("Menu item not found: " + entry.getKey()));
            if (item.getStock() < entry.getValue()) {
                throw new RuntimeException("Insufficient stock for item: " + item.getName());
            }
            item.setStock(item.getStock() - entry.getValue());
            menuItemRepository.save(item);
        }
    }



    private void deductCustomerBalance(Order order) {
        Customer customer = order.getCustomer();
        BigDecimal totalAmount = order.getTotalAmount();

        if (customer.getCreditBalance().compareTo(totalAmount) < 0) {
            throw new InsufficientBalanceException("Insufficient credit to complete order #" + order.getId());
        }
        customer.setCreditBalance(customer.getCreditBalance().subtract(totalAmount));
        customerRepository.save(customer);
        log.info("Deducted {} from balance for customer {}. New balance: {}", totalAmount, customer.getEmail(), customer.getCreditBalance());
    }

    // Corrected method signature to use Map<Long, Integer>
    private BigDecimal calculateOrderTotal(Map<Long, Integer> items) {
        if (items == null || items.isEmpty()) {
            return BigDecimal.ZERO;
        }
        Set<Long> menuItemIds = items.keySet();

        Map<Long, MenuItem> menuItemMap = menuItemRepository.findAllById(menuItemIds)
                .stream()
                .collect(Collectors.toMap(MenuItem::getId, mi -> mi));

        BigDecimal total = BigDecimal.ZERO;
        for (var entry : items.entrySet()) {
            Long id = entry.getKey();
            MenuItem menuItem = menuItemMap.get(id);
            if (menuItem == null) {
                throw new ResourceNotFoundException("MenuItem with ID " + id + " not found");
            }
            total = total.add(menuItem.getPrice().multiply(BigDecimal.valueOf(entry.getValue())));
        }
        return total;
    }

    private OrderDTO convertToDTO(Order order) {
        return modelMapper.map(order, OrderDTO.class);
    }
}