package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.CustomerResponseDTO;
import com.SmartCanteen.Backend.DTOs.CustomerUpdateDTO;
import com.SmartCanteen.Backend.DTOs.OrderDTO;
import com.SmartCanteen.Backend.Services.CustomerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/customer")
@RequiredArgsConstructor
public class CustomerController {

    private final CustomerService customerService;

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
    public ResponseEntity<?> getCreditBalance() {
        var balance = customerService.getCreditBalance();
        return ResponseEntity.ok(balance);
    }

    @PutMapping("/profile")
    public ResponseEntity<CustomerResponseDTO> updateProfile(@Valid @RequestBody CustomerUpdateDTO updateDTO) {
        CustomerResponseDTO updatedCustomer = customerService.updateProfile(updateDTO);
        return ResponseEntity.ok(updatedCustomer);
    }

    // Optional: Add delete endpoint if you want to support deleting customer profiles
    @DeleteMapping("/profile")
    public ResponseEntity<?> deleteProfile() {
        customerService.deleteCurrentCustomer();
        return ResponseEntity.ok("Customer deleted successfully");
    }
}
