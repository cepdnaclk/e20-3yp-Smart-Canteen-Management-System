package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.AdminDTO;
import com.SmartCanteen.Backend.Services.AdminService;
import com.SmartCanteen.Backend.Services.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final OrderService orderService;

    @GetMapping("/dashboard")
    public ResponseEntity<?> getDashboard() {
        var dashboardData = adminService.getDashboardData();
        return ResponseEntity.ok(dashboardData);
    }

    @GetMapping("/users")
    public ResponseEntity<?> getAllUsers() {
        var users = adminService.getAllUsers();
        return ResponseEntity.ok(users);
    }

    @PutMapping("/user/{id}/role")
    public ResponseEntity<?> updateUserRole(@PathVariable Long id, @RequestParam String role) {
        adminService.updateUserRole(id, role);
        return ResponseEntity.ok("User role updated successfully");
    }

    @GetMapping("/orders/{orderId}/total-value")
    @PreAuthorize("hasRole('ADMIN') or hasRole('CUSTOMER')")
    public ResponseEntity<BigDecimal> getOrderTotalValue(@PathVariable Long orderId) {
        BigDecimal totalValue = orderService.calculateOrderValue(orderId);
        return ResponseEntity.ok(totalValue);
    }

}
