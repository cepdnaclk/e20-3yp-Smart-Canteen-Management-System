package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.OrderDTO;
import com.SmartCanteen.Backend.Entities.*;
import com.SmartCanteen.Backend.Repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final CustomerRepository customerRepository;
    private final NotificationService notificationService;

    @Transactional
    public OrderDTO placeOrder(OrderDTO orderDTO) {
        Customer customer = customerRepository.findById(orderDTO.getCustomerId())
                .orElseThrow(() -> new RuntimeException("Customer not found"));

        // TODO: Validate stock, calculate total, deduct balance, update stock with concurrency control

        // For simplicity, assume totalAmount is set correctly in orderDTO
        if (customer.getCreditBalance().compareTo(orderDTO.getTotalAmount()) < 0) {
            throw new RuntimeException("Insufficient credit balance");
        }

        customer.setCreditBalance(customer.getCreditBalance().subtract(orderDTO.getTotalAmount()));
        customerRepository.save(customer);

        Order order = new Order();
        order.setCustomer(customer);
        order.setItems(orderDTO.getItems());
        order.setTotalAmount(orderDTO.getTotalAmount());
        order.setStatus(OrderStatus.PENDING);
        order.setOrderTime(LocalDateTime.now());
        order.setScheduledTime(orderDTO.getScheduledTime());

        Order savedOrder = orderRepository.save(order);

        notificationService.sendNotification(customer, "Order placed successfully with ID: " + savedOrder.getId());

        // Map savedOrder to OrderDTO and return (mapping code omitted for brevity)
        orderDTO.setId(savedOrder.getId());
        orderDTO.setStatus(savedOrder.getStatus().name());
        orderDTO.setOrderTime(savedOrder.getOrderTime());

        return orderDTO;
    }

    public List<OrderDTO> getOrderHistory(Long customerId) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new RuntimeException("Customer not found"));

        List<Order> orders = orderRepository.findByCustomer(customer);

        // Map orders to OrderDTO list (mapping code omitted)
        // ...

        return null; // Replace with actual mapped list
    }
}
