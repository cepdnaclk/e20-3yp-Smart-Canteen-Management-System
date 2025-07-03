package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.OrderDTO;
import com.SmartCanteen.Backend.Services.AuthService;
import com.SmartCanteen.Backend.Services.OrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;
    private final AuthService authService; // Needed for getting user ID

    @PostMapping("/place")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<OrderDTO> placeOrder(@AuthenticationPrincipal UserDetails userDetails, @Valid @RequestBody OrderDTO orderDTO) {
        // Basic validation to ensure the user is placing their own order
        if (!userDetails.getUsername().equals(orderDTO.getEmail())) {
            throw new IllegalArgumentException("Order email does not match authenticated user.");
        }
        OrderDTO placedOrder = orderService.placeOrder(orderDTO);
        return ResponseEntity.ok(placedOrder);
    }

    @GetMapping("/my-history")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<List<OrderDTO>> getMyOrders(@AuthenticationPrincipal UserDetails userDetails) {
        List<OrderDTO> orders = orderService.getOrderHistory(userDetails.getUsername());
        return ResponseEntity.ok(orders);
    }

    @PutMapping("/my-history/{orderId}/cancel")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<OrderDTO> cancelOrder(@AuthenticationPrincipal UserDetails userDetails, @PathVariable Long orderId) {
        // The service can internally check if the order belongs to the user
        OrderDTO cancelledOrder = orderService.cancelOrder(orderId, userDetails.getUsername(), 0.0);
        return ResponseEntity.ok(cancelledOrder);
    }

    // --- Merchant Endpoints ---

    @GetMapping("/merchant/pending")
    @PreAuthorize("hasRole('MERCHANT')")
    public ResponseEntity<List<OrderDTO>> getPendingOrders() {
        return ResponseEntity.ok(orderService.getPendingOrders());
    }

    @GetMapping("/merchant/accepted")
    @PreAuthorize("hasRole('MERCHANT')")
    public ResponseEntity<List<OrderDTO>> getAcceptedOrders() {
        return ResponseEntity.ok(orderService.getAcceptedOrders());
    }

    @GetMapping("/merchant/completed")
    @PreAuthorize("hasRole('MERCHANT')")
    public ResponseEntity<List<OrderDTO>> getCompletedOrders() {
        return ResponseEntity.ok(orderService.getCompletedOrders());
    }

    @PutMapping("/{orderId}/accept")
    @PreAuthorize("hasRole('MERCHANT')")
    public ResponseEntity<OrderDTO> acceptOrder(@PathVariable Long orderId) {
        OrderDTO updatedOrder = orderService.acceptOrder(orderId);
        return ResponseEntity.ok(updatedOrder);
    }

    @PutMapping("/{orderId}/complete")
    @PreAuthorize("hasRole('MERCHANT')")
    public ResponseEntity<OrderDTO> completeOrder(@PathVariable Long orderId) {
        OrderDTO updatedOrder = orderService.completeOrder(orderId);
        return ResponseEntity.ok(updatedOrder);
    }
}