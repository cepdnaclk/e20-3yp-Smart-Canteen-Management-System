package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.AdminDTO;
import com.SmartCanteen.Backend.Services.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

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
}
