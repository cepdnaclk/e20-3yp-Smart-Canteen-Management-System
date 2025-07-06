//package com.SmartCanteen.Backend.Controllers;
//
//import com.SmartCanteen.Backend.DTOs.*;
//import com.SmartCanteen.Backend.Services.*;
//import jakarta.validation.Valid;
//import lombok.RequiredArgsConstructor;
//import org.springframework.http.ResponseEntity;
//import org.springframework.security.core.annotation.AuthenticationPrincipal;
//import org.springframework.security.core.userdetails.UserDetails;
//import org.springframework.web.bind.annotation.*;
//
//import java.math.BigDecimal;
//import java.util.List;
//import java.util.Map;
//import java.util.stream.Collectors;
//
//@RestController
//@RequestMapping("/api/customer")
//@RequiredArgsConstructor
//public class CustomerController {
//
//    private final CustomerService customerService;
//    private final CartService cartService;
//    private final ScheduledOrderService scheduledOrderService;
//    private final NotificationService notificationService;
//    private final AuthService authService;
//
//    @GetMapping("/profile")
//    public ResponseEntity<CustomerResponseDTO> getProfile() {
//        CustomerResponseDTO customer = customerService.getProfile();
//        return ResponseEntity.ok(customer);
//    }
//
//    @GetMapping("/menu")
//    public ResponseEntity<List<?>> getMenu() {
//        var menu = customerService.getMenuItems();
//        return ResponseEntity.ok(menu);
//    }
//
//    @PostMapping("/order")
//    public ResponseEntity<OrderDTO> placeOrder(@Valid @RequestBody OrderDTO orderDTO) {
//        OrderDTO order = customerService.placeOrder(orderDTO);
//        return ResponseEntity.ok(order);
//    }
//
//    @GetMapping("/orders")
//    public ResponseEntity<List<OrderDTO>> getOrderHistory() {
//        List<OrderDTO> orders = customerService.getOrderHistory();
//        return ResponseEntity.ok(orders);
//    }
//
//    @GetMapping("/balance")
//    public ResponseEntity<BigDecimal> getCreditBalance(@AuthenticationPrincipal UserDetails userDetails) {
//        Long userId = authService.getUserIdFromUserDetails(userDetails);
//        BigDecimal balance = customerService.getCreditBalance(userId);
//        return ResponseEntity.ok(balance);
//    }
//
//    @PutMapping("/profile")
//    public ResponseEntity<CustomerResponseDTO> updateProfile(@Valid @RequestBody CustomerUpdateDTO updateDTO) {
//        CustomerResponseDTO updatedCustomer = customerService.updateProfile(updateDTO);
//        return ResponseEntity.ok(updatedCustomer);
//    }
//
//    @DeleteMapping("/profile")
//    public ResponseEntity<?> deleteProfile() {
//        customerService.deleteCurrentCustomer();
//        return ResponseEntity.ok("Customer deleted successfully");
//    }
//
//    @PostMapping("/order/cart")
//    public ResponseEntity<OrderDTO> placeOrderFromCart(@AuthenticationPrincipal UserDetails userDetails) {
//        Long userId = authService.getUserIdFromUserDetails(userDetails);
//        CartDTO cart = cartService.getCart(userId);
//        OrderDTO orderDTO = new OrderDTO();
//        orderDTO.setId(userId);
//
//        // Convert Map<Long, Integer> to Map<String, Integer>
//        Map<Long, Integer> cartItems = (Map<Long, Integer>) cart.getItems();
//        Map<String, Integer> orderItems = cartItems.entrySet().stream()
//                .collect(Collectors.toMap(
//                        e -> String.valueOf(e.getKey()),
//                        Map.Entry::getValue
//                ));
//        orderDTO.setItems(orderItems);
//
//
//        // Set email if required by your service
//        orderDTO.setEmail(userDetails.getUsername());
//
//        OrderDTO order = customerService.placeOrder(orderDTO);
//        cartService.clearCart(userId);
//        BigDecimal newBalance = customerService.getCreditBalance(userId);
//        notificationService.sendOrderNotification(userId, order, newBalance);
//        return ResponseEntity.ok(order);
//    }
//
//
//}


package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.*;
import com.SmartCanteen.Backend.Services.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/customer")
@RequiredArgsConstructor
@PreAuthorize("hasRole('CUSTOMER')")
public class CustomerController {

    private final CustomerService customerService;
    // other services

    @GetMapping("/profile")
    public ResponseEntity<CustomerResponseDTO> getProfile() {
        CustomerResponseDTO customer = customerService.getProfile();
        return ResponseEntity.ok(customer);
    }

    @PutMapping("/profile")
    public ResponseEntity<CustomerResponseDTO> updateProfile(@Valid @RequestBody CustomerUpdateDTO updateDTO) {
        CustomerResponseDTO updatedCustomer = customerService.updateProfile(updateDTO);
        return ResponseEntity.ok(updatedCustomer);
    }

    // --- NEW: PROFILE PICTURE UPLOAD ENDPOINT ---
    @PostMapping("/profile/picture")
    public ResponseEntity<CustomerResponseDTO> updateProfilePicture(@RequestParam("file") MultipartFile file) {
        CustomerResponseDTO updatedCustomer = customerService.updateProfilePicture(file);
        return ResponseEntity.ok(updatedCustomer);
    }

    @DeleteMapping("/profile")
    public ResponseEntity<?> deleteProfile() {
        customerService.deleteCurrentCustomer();
        return ResponseEntity.ok(Map.of("message", "Customer profile deleted successfully"));
    }

    // other endpoints like /menu, /orders, etc.
}