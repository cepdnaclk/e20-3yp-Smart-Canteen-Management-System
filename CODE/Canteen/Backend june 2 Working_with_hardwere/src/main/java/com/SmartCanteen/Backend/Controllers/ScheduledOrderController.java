package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.ScheduledOrderDTO;
import com.SmartCanteen.Backend.Services.AuthService;
import com.SmartCanteen.Backend.Services.ScheduledOrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/scheduled-orders")
@RequiredArgsConstructor
public class ScheduledOrderController {
    private final ScheduledOrderService scheduledOrderService;
    private final AuthService authService;

    @PostMapping
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ScheduledOrderDTO> scheduleOrder(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody ScheduledOrderDTO dto) {
        Long userId = authService.getUserIdFromUserDetails(userDetails);
        return ResponseEntity.ok(scheduledOrderService.scheduleOrder(userId, dto));
    }

    @GetMapping
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<List<ScheduledOrderDTO>> getScheduledOrders(
            @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = authService.getUserIdFromUserDetails(userDetails);
        return ResponseEntity.ok(scheduledOrderService.getScheduledOrders(userId));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<Void> cancelScheduledOrder(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        Long userId = authService.getUserIdFromUserDetails(userDetails);
        scheduledOrderService.cancelScheduledOrder(userId, id);
        return ResponseEntity.noContent().build();
    }
}
