package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.OrderDTO;
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

    @PostMapping("/place")
    // @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<OrderDTO> placeOrder(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody OrderDTO orderDTO) {
        // Validate that the provided email matches the authenticated user
        if (!userDetails.getUsername().equals(orderDTO.getEmail())) {
            throw new IllegalArgumentException("Email does not match authenticated user");
        }
        OrderDTO placedOrder = orderService.placeOrder(orderDTO);
        return ResponseEntity.ok(placedOrder);
    }

    @GetMapping("/my-orders")
    //  @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<List<OrderDTO>> getMyOrders(
            @AuthenticationPrincipal UserDetails userDetails) {
        List<OrderDTO> orders = orderService.getOrderHistory(userDetails.getUsername());
        return ResponseEntity.ok(orders);
    }

    @GetMapping("/merchant/pending")
    // @PreAuthorize("hasRole('MERCHANT')")
    public ResponseEntity<List<OrderDTO>> getPendingOrders() {
        return ResponseEntity.ok(orderService.getPendingOrders());
    }

    @PutMapping("/{orderId}/status")
    //  @PreAuthorize("hasRole('MERCHANT')")
    public ResponseEntity<OrderDTO> updateOrderStatus(
            @PathVariable Long orderId,
            @RequestParam String status) {
        return ResponseEntity.ok(orderService.updateOrderStatus(orderId, status));
    }

    @PutMapping("/cancel/{orderId}")
    // @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<OrderDTO> cancelOrder(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long orderId,
            @RequestParam(defaultValue = "0.0") double cancellationFee) {
        OrderDTO cancelledOrder = orderService.cancelOrder(orderId, userDetails.getUsername(), cancellationFee);
        return ResponseEntity.ok(cancelledOrder);
    }

    @GetMapping("/merchant/all")
    //@PreAuthorize("hasRole('MERCHANT')")
    public ResponseEntity<List<OrderDTO>> getAllOrdersForMerchant() {
        List<OrderDTO> orders = orderService.getAllOrders();
        return ResponseEntity.ok(orders);

    }

    @GetMapping("/merchant/accepted")
    // @PreAuthorize("hasRole('MERCHANT')")
    public ResponseEntity<List<OrderDTO>> getAcceptedOrders() {
        return ResponseEntity.ok(orderService.getAcceptedOrders());
    }

    @GetMapping("/merchant/completed")
    // @PreAuthorize("hasRole('MERCHANT')")
    public ResponseEntity<List<OrderDTO>> getCompletedOrders() {
        return ResponseEntity.ok(orderService.getCompletedOrders());
    }


    /// //////////////////////New End Points

    // Accept a pending order (pending -> accepted)
    @PutMapping("/{orderId}/accept")
    public ResponseEntity<OrderDTO> acceptOrder(@PathVariable Long orderId) {
        OrderDTO updatedOrder = orderService.acceptOrder(orderId);
        return ResponseEntity.ok(updatedOrder);
    }

    // Complete an accepted order (accepted -> completed)
    @PutMapping("/{orderId}/complete")
    public ResponseEntity<OrderDTO> completeOrder(@PathVariable Long orderId) {
        OrderDTO updatedOrder = orderService.completeOrder(orderId);
        return ResponseEntity.ok(updatedOrder);
    }

    // Complete a pending order directly (pending -> completed)
    @PutMapping("/{orderId}/completeDirectly")
    public ResponseEntity<OrderDTO> completeOrderDirectly(@PathVariable Long orderId) {
        OrderDTO updatedOrder = orderService.completeOrderDirectlyFromPending(orderId);
        return ResponseEntity.ok(updatedOrder);


    }
}