package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.CustomerDTO;
import com.SmartCanteen.Backend.DTOs.MerchantDTO;
import com.SmartCanteen.Backend.Services.UserManagementService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class UserManagementController {

    private final UserManagementService userManagementService;

    @GetMapping("/customers")
    public ResponseEntity<List<CustomerDTO>> getAllCustomers() {
        return ResponseEntity.ok(userManagementService.getAllCustomers());
    }

    @GetMapping("/merchants")
    public ResponseEntity<List<MerchantDTO>> getAllMerchants() {
        return ResponseEntity.ok(userManagementService.getAllMerchants());
    }

    @PutMapping("/{userId}/deactivate")
    public ResponseEntity<?> deactivateUser(@PathVariable Long userId) {
        userManagementService.deactivateUser(userId);
        return ResponseEntity.ok(Map.of("message", "User has been deactivated successfully."));
    }

    @PutMapping("/{userId}/activate")
    public ResponseEntity<?> activateUser(@PathVariable Long userId) {
        userManagementService.activateUser(userId);
        return ResponseEntity.ok(Map.of("message", "User has been activated successfully."));
    }
}