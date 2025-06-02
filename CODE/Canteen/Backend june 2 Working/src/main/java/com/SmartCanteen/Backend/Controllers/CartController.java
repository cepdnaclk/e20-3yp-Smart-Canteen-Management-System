package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.CartDTO;
import com.SmartCanteen.Backend.DTOs.CartItemDTO;
import com.SmartCanteen.Backend.Services.AuthService;
import com.SmartCanteen.Backend.Services.CartService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/cart")
@RequiredArgsConstructor
public class CartController {
    private final CartService cartService;
    private final AuthService authService;

    @GetMapping
    public ResponseEntity<CartDTO> getCart(@AuthenticationPrincipal UserDetails userDetails) {
        Long userId = authService.getUserIdFromUserDetails(userDetails);
        return ResponseEntity.ok(cartService.getCart(userId));
    }

    @PostMapping("/add")
    public ResponseEntity<CartDTO> addItem(@AuthenticationPrincipal UserDetails userDetails, @RequestBody CartItemDTO item) {
        Long userId = authService.getUserIdFromUserDetails(userDetails);
        return ResponseEntity.ok(cartService.addItem(userId, item));
    }

    @PostMapping("/remove")
    public ResponseEntity<CartDTO> removeItem(@AuthenticationPrincipal UserDetails userDetails, @RequestBody CartItemDTO item) {
        Long userId = authService.getUserIdFromUserDetails(userDetails);
        return ResponseEntity.ok(cartService.removeItem(userId, item));
    }

    @PostMapping("/clear")
    public ResponseEntity<CartDTO> clearCart(@AuthenticationPrincipal UserDetails userDetails) {
        Long userId = authService.getUserIdFromUserDetails(userDetails);
        return ResponseEntity.ok(cartService.clearCart(userId));
    }
}
