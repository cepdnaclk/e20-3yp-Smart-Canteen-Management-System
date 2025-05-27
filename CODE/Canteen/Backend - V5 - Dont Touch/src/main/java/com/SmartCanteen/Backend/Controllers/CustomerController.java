package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.*;
import com.SmartCanteen.Backend.Services.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/customer")
@RequiredArgsConstructor
public class CustomerController {

    private final CustomerService customerService;
    private final CartService cartService;
    private final ScheduledOrderService scheduledOrderService;
    private final NotificationService notificationService;
    private final AuthService authService;

    @GetMapping("/profile")
    public ResponseEntity<CustomerResponseDTO> getProfile() {
        CustomerResponseDTO customer = customerService.getProfile();
        return ResponseEntity.ok(customer);
    }

    @GetMapping("/menu")
    public ResponseEntity<List<?>> getMenu() {
        var menu = customerService.getMenuItems();
        return ResponseEntity.ok(menu);
    }

    @PostMapping("/order")
    public ResponseEntity<OrderDTO> placeOrder(@Valid @RequestBody OrderDTO orderDTO) {
        OrderDTO order = customerService.placeOrder(orderDTO);
        return ResponseEntity.ok(order);
    }

    @GetMapping("/orders")
    public ResponseEntity<List<OrderDTO>> getOrderHistory() {
        List<OrderDTO> orders = customerService.getOrderHistory();
        return ResponseEntity.ok(orders);
    }

    @GetMapping("/balance")
    public ResponseEntity<BigDecimal> getCreditBalance(@AuthenticationPrincipal UserDetails userDetails) {
        Long userId = authService.getUserIdFromUserDetails(userDetails);
        BigDecimal balance = customerService.getCreditBalance(userId);
        return ResponseEntity.ok(balance);
    }

    @PutMapping("/profile")
    public ResponseEntity<CustomerResponseDTO> updateProfile(@Valid @RequestBody CustomerUpdateDTO updateDTO) {
        CustomerResponseDTO updatedCustomer = customerService.updateProfile(updateDTO);
        return ResponseEntity.ok(updatedCustomer);
    }

    @DeleteMapping("/profile")
    public ResponseEntity<?> deleteProfile() {
        customerService.deleteCurrentCustomer();
        return ResponseEntity.ok("Customer deleted successfully");
    }

    @PostMapping("/order/cart")
    public ResponseEntity<OrderDTO> placeOrderFromCart(@AuthenticationPrincipal UserDetails userDetails) {
        Long userId = authService.getUserIdFromUserDetails(userDetails);
        CartDTO cart = cartService.getCart(userId);
        OrderDTO orderDTO = new OrderDTO();
        orderDTO.setUserId(userId);

        orderDTO.setItems((Map<Long, Integer>) cart.getItems());
        OrderDTO order = customerService.placeOrder(orderDTO);
        cartService.clearCart(userId);
        BigDecimal newBalance = customerService.getCreditBalance(userId);
        notificationService.sendOrderNotification(userId, order, newBalance);
        return ResponseEntity.ok(order);
    }
}
