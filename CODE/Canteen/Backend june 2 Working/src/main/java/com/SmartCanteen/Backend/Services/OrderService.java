package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.OrderDTO;
import com.SmartCanteen.Backend.Entities.*;
import com.SmartCanteen.Backend.Exceptions.InsufficientBalanceException;
import com.SmartCanteen.Backend.Repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class  OrderService {

    private final OrderRepository orderRepository;
    private final MenuItemRepository menuItemRepository;
    private final CustomerRepository customerRepository;
    private final NotificationService notificationService;
    private final ReceiptRepository receiptRepository;

    // Place a new order
//    @Transactional
//    public OrderDTO placeOrder(OrderDTO orderDTO) {
//        if (orderDTO.getEmail() == null) {
//            throw new IllegalArgumentException("userEmail must not be null");
//        }
//        Map<String, Integer> itemsMap = orderDTO.getItems(); // No conversion needed
//
//        // Calculate total
//        BigDecimal total = calculateOrderTotal(itemsMap);
//
//        // Fetch customer
//        Customer customer = customerRepository.findByEmail(orderDTO.getEmail())
//                .orElseThrow(() -> new RuntimeException("Customer not found: " + orderDTO.getEmail()));
//
//        // Create order
//        Order order = new Order();
//        order.setCustomer(customer);
//        order.setEmail(customer.getEmail());
//        order.setStatus(OrderStatus.PENDING);
//        order.setOrderTime(orderDTO.getOrderTime() != null ? orderDTO.getOrderTime() : LocalDateTime.now());
//        order.setScheduledTime(orderDTO.getScheduledTime());
//        order.setItems(itemsMap);
//        order.setTotalAmount(total);
//
//        // Save and return
//        order = orderRepository.save(order);
//        return convertToDTO(order);
//    }

    @Transactional
    public OrderDTO placeOrder(OrderDTO orderDTO) {
        if (orderDTO.getEmail() == null) {
            throw new IllegalArgumentException("userEmail must not be null");
        }
        Map<String, Integer> itemsMap = orderDTO.getItems();

        BigDecimal total = calculateOrderTotal(itemsMap);

        Customer customer = customerRepository.findByEmail(orderDTO.getEmail())
                .orElseThrow(() -> new RuntimeException("Customer not found: " + orderDTO.getEmail()));

        // Check if customer has enough credit balance
        if (customer.getCreditBalance().compareTo(total) < 0) {
            throw new InsufficientBalanceException("Insufficient credit balance to place order");
        }



        Order order = new Order();
        order.setCustomer(customer);
        order.setEmail(customer.getEmail());
        order.setStatus(OrderStatus.PENDING);
        order.setOrderTime(orderDTO.getOrderTime() != null ? orderDTO.getOrderTime() : LocalDateTime.now());
        order.setScheduledTime(orderDTO.getScheduledTime());
        order.setItems(itemsMap);
        order.setTotalAmount(total);

        order = orderRepository.save(order);
        return convertToDTO(order);
    }


    // Calculate total price
    private BigDecimal calculateOrderTotal(Map<String, Integer> items) {
        if (items == null || items.isEmpty()) {
            return BigDecimal.ZERO;
        }
        Set<Long> menuItemIds = items.keySet().stream()
                .map(Long::parseLong)
                .collect(Collectors.toSet());
        Map<Long, MenuItem> menuItemMap = menuItemRepository.findAllById(menuItemIds)
                .stream()
                .collect(Collectors.toMap(MenuItem::getId, mi -> mi));
        BigDecimal total = BigDecimal.ZERO;
        for (var entry : items.entrySet()) {
            Long id = Long.parseLong(entry.getKey());
            MenuItem menuItem = menuItemMap.get(id);
            if (menuItem == null) {
                throw new RuntimeException("MenuItem with ID " + entry.getKey() + " not found");
            }
            total = total.add(menuItem.getPrice().multiply(BigDecimal.valueOf(entry.getValue())));
        }
        return total;
    }

    public List<OrderDTO> getPendingOrders() {
        return orderRepository.findByStatus(OrderStatus.PENDING)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    // Get order history for a customer (by email)
    public List<OrderDTO> getOrderHistory(String email) {
        Customer customer = customerRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Customer not found: " + email));
        return orderRepository.findByCustomer(customer).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    // Cancel order (with cancellation fee)
    @Transactional
    public OrderDTO cancelOrder(Long orderId, String username, double cancellationFee) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        if (order.getStatus() == OrderStatus.COMPLETED) {
            throw new RuntimeException("Cannot cancel completed order");
        }

        BigDecimal fee = BigDecimal.valueOf(cancellationFee);
        Customer customer = order.getCustomer();
        customer.setCreditBalance(customer.getCreditBalance().add(order.getTotalAmount().subtract(fee)));
        customerRepository.save(customer);

        order.setStatus(OrderStatus.CANCELLED);
        return convertToDTO(orderRepository.save(order));
    }

    // Update order status (accept, complete, etc.)
    @Transactional
//    public OrderDTO updateOrderStatus(Long orderId, String status) {
//        Order order = orderRepository.findById(orderId)
//                .orElseThrow(() -> new RuntimeException("Order not found"));
//
//        OrderStatus newStatus = OrderStatus.valueOf(status.toUpperCase());
//        order.setStatus(newStatus);
//
//        // If accepted, deduct credit, generate receipt, and notify user
//        if (newStatus == OrderStatus.ACCEPTED) {
//            handleOrderAcceptance(order);
//        }
//
//        // If completed, notify user
//        if (newStatus == OrderStatus.COMPLETED) {
//            notificationService.sendNotification(
//                    order.getCustomer(),
//                    "Your order #" + orderId + " is ready for pickup!"
//            );
//        }
//        return convertToDTO(orderRepository.save(order));
//    }

    // Handle credit deduction, receipt, and notification on acceptance

    // Convert item IDs to names for receipt
    private Map<String, Integer> getItemNames(Map<String, Integer> itemIds) {
        Set<Long> menuItemIds = itemIds.keySet().stream()
                .map(Long::parseLong)
                .collect(Collectors.toSet());
        return menuItemRepository.findAllById(menuItemIds).stream()
                .collect(Collectors.toMap(
                        MenuItem::getName,
                        item -> itemIds.get(String.valueOf(item.getId()))
                ));
    }

    // Build receipt email content
    private String buildReceiptMessage(Receipt receipt) {
        return String.format("""
            Order Receipt #%s
            Date: %s
            Items:
            %s
            Total: ₹%.2f
            Thank you for your order!
            """,
                receipt.getOrder().getId(),
                receipt.getGeneratedDate(),
                receipt.getItems().entrySet().stream()
                        .map(e -> "- " + e.getKey() + " x" + e.getValue())
                        .collect(Collectors.joining("\n")),
                receipt.getTotalAmount()
        );
    }

    // Convert Order entity to DTO
    private OrderDTO convertToDTO(Order order) {
        OrderDTO dto = new OrderDTO();
        dto.setId(order.getId());
        dto.setEmail(order.getEmail());
        dto.setItems(order.getItems()); // Already Map<String, Integer>
        dto.setTotalAmount(order.getTotalAmount());
        dto.setStatus(order.getStatus() != null ? order.getStatus().name() : null);
        dto.setOrderTime(order.getOrderTime());
        dto.setScheduledTime(order.getScheduledTime());
        return dto;
    }

    public BigDecimal calculateOrderValue(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found: " + orderId));
        return order.getTotalAmount();
    }

    public List<OrderDTO> getAllOrders() {
        return orderRepository.findAll().stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public OrderDTO updateOrderStatus(Long orderId, String status) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        OrderStatus newStatus = OrderStatus.valueOf(status.toUpperCase());
        order.setStatus(newStatus);

        if (newStatus == OrderStatus.COMPLETED) {
            if (!order.isBalanceDeducted()) {
                deductCustomerBalance(order);  // Deduct only once
                order.setBalanceDeducted(true); // Mark as deducted
            }

            notificationService.sendNotification(
                    order.getCustomer(),
                    "Your order #" + orderId + " is ready for pickup!"
            );
        }

        return convertToDTO(orderRepository.save(order));
    }


    private void deductCustomerBalance(Order order) {
        Customer customer = order.getCustomer();
        BigDecimal totalAmount = order.getTotalAmount();

        if (customer.getCreditBalance().compareTo(totalAmount) < 0) {
            throw new RuntimeException("Insufficient credit balance to complete order");
        }

        customer.setCreditBalance(customer.getCreditBalance().subtract(totalAmount));
        customerRepository.save(customer);

        notificationService.sendNotification(customer,
                "Rs" + totalAmount + " has been deducted from your balance for order #" + order.getId());
    }







    /// ///////////////////New codes

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

    @Transactional
    public OrderDTO completeOrder(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        if (order.getStatus() != OrderStatus.ACCEPTED) {
            throw new IllegalStateException("Only accepted orders can be completed.");
        }

        order.setStatus(OrderStatus.COMPLETED);
        if (!order.isBalanceDeducted()) {
            deductCustomerBalance(order);
            order.setBalanceDeducted(true);
        }

        notificationService.sendNotification(
                order.getCustomer(),
                "Your order #" + orderId + " is ready for pickup!"
        );

        return convertToDTO(orderRepository.save(order));
    }

    @Transactional
    public OrderDTO completeOrderDirectlyFromPending(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        if (order.getStatus() != OrderStatus.PENDING) {
            throw new IllegalStateException("Only pending orders can be directly completed.");
        }

        order.setStatus(OrderStatus.COMPLETED);
        if (!order.isBalanceDeducted()) {
            deductCustomerBalance(order);
            order.setBalanceDeducted(true);
        }

        notificationService.sendNotification(
                order.getCustomer(),
                "Your order #" + orderId + " is ready for pickup!"
        );

        return convertToDTO(orderRepository.save(order));
    }







}
