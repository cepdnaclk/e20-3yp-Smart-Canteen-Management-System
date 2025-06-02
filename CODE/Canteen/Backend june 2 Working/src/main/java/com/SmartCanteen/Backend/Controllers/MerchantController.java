package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.MenuItemDTO;
import com.SmartCanteen.Backend.DTOs.MerchantResponseDTO;
import com.SmartCanteen.Backend.DTOs.MerchantUpdateDTO;
import com.SmartCanteen.Backend.Services.MerchantService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/merchant")
@RequiredArgsConstructor
public class MerchantController {

    private final MerchantService merchantService;

    @GetMapping("/profile")
    public ResponseEntity<MerchantResponseDTO> getProfile() {
        MerchantResponseDTO merchant = merchantService.getProfile();
        return ResponseEntity.ok(merchant);
    }

    @PutMapping("/profile")
    public ResponseEntity<MerchantResponseDTO> updateProfile(@Valid @RequestBody MerchantUpdateDTO updateDTO) {
        MerchantResponseDTO updatedMerchant = merchantService.updateProfile(updateDTO);
        return ResponseEntity.ok(updatedMerchant);
    }

    @DeleteMapping("/profile")
    public ResponseEntity<?> deleteProfile() {
        merchantService.deleteCurrentMerchant();
        return ResponseEntity.ok("Merchant deleted successfully");
    }

    @GetMapping("/menu")
    public ResponseEntity<List<MenuItemDTO>> getMenuItems() {
        List<MenuItemDTO> menu = merchantService.getMenuItems();
        return ResponseEntity.ok(menu);
    }

    @PostMapping("/menu")
    public ResponseEntity<?> addMenuItem(@Valid @RequestBody MenuItemDTO menuItemDTO) {
        merchantService.addMenuItem(menuItemDTO);
        return ResponseEntity.ok("Menu item added successfully");
    }

    @PutMapping("/menu/{id}")
    public ResponseEntity<?> updateMenuItem(@PathVariable Long id, @Valid @RequestBody MenuItemDTO menuItemDTO) {
        merchantService.updateMenuItem(id, menuItemDTO);
        return ResponseEntity.ok("Menu item updated successfully");
    }

    @DeleteMapping("/menu/{id}")
    public ResponseEntity<?> deleteMenuItem(@PathVariable Long id) {
        merchantService.deleteMenuItem(id);
        return ResponseEntity.ok("Menu item deleted successfully");
    }

    @PostMapping("/topup/{customerId}")
    public ResponseEntity<?> topUpCustomerCredit(@PathVariable Long customerId, @RequestParam double amount) {
        merchantService.topUpCustomerCredit(customerId, amount);
        return ResponseEntity.ok("Customer credit topped up successfully");
    }
}
