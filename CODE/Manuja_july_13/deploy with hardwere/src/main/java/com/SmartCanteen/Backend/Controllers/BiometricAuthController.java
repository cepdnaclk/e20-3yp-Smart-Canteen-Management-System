package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.*;
import com.SmartCanteen.Backend.Entities.OrderStatus;
import com.SmartCanteen.Backend.Services.BiometricAuthService;
import com.SmartCanteen.Backend.Services.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/biometric")
public class BiometricAuthController {

    private final BiometricAuthService biometricAuthService;
    private final OrderService orderService;

    @Autowired
    public BiometricAuthController(BiometricAuthService biometricAuthService,
                                   OrderService orderService) {
        this.biometricAuthService = biometricAuthService;
        this.orderService = orderService;
    }

    // Endpoint 1: Initiate verification process
    @PostMapping("/initiate")
    public ResponseEntity<InitiateResponseDTO> initiateVerification(
            @RequestBody InitiateRequestDTO request,
            @RequestHeader("Authorization") String authHeader) {

        String token = extractToken(authHeader);
        InitiateResponseDTO response = biometricAuthService.initiateVerification(
                request.getEmail(),
                request.getOrderId(),
                token
        );

        return ResponseEntity.ok(response);
    }

    // Endpoint 2: Confirm verification and complete order
    @PostMapping("/confirm")
    public ResponseEntity<BiometricAuthResponseDTO> confirmVerification(
            @RequestBody ConfirmRequestDTO request,
            @RequestHeader("Authorization") String authHeader) {

        String token = extractToken(authHeader);
        BiometricAuthResponseDTO response = biometricAuthService.confirmVerification(
                request.getEmail(),
                request.getOrderId(),
                request.getConfidence(),
                request.getScannedId(),
                token
        );


        if (response.isAuthenticated()) {
            try {
                OrderDTO updatedOrder = orderService.completeOrderDirectlyFromPending(
                        request.getOrderId()
                );

                response.setMessage("Order completed successfully, status: " + updatedOrder.getStatus());
                response.setOrderStatus(OrderStatus.valueOf(updatedOrder.getStatus()));
            } catch (Exception e) {
                response.setAuthenticated(false);
                response.setMessage("Order completion failed: " + e.getMessage());
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
            }
        }

        return ResponseEntity.ok(response);
    }

    private String extractToken(String authHeader) {
        return authHeader.startsWith("Bearer ") ?
                authHeader.substring(7) : authHeader;
    }
}