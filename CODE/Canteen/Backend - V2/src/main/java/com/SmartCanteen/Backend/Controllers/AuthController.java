package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.*;
import com.SmartCanteen.Backend.Services.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponseDTO> login(@RequestBody LoginRequestDTO loginRequest) {
        AuthResponseDTO response = authService.authenticateUser(loginRequest);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register/customer")
    public ResponseEntity<CustomerResponseDTO> registerCustomer(@Valid @RequestBody CustomerRequestDTO customerRequestDTO) {
        CustomerResponseDTO response = authService.registerCustomer(customerRequestDTO);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register/merchant")
    public ResponseEntity<MerchantResponseDTO> registerMerchant(@Valid @RequestBody MerchantRequestDTO merchantRequestDTO) {
        MerchantResponseDTO response = authService.registerMerchant(merchantRequestDTO);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register/admin")
    public ResponseEntity<AdminResponseDTO> registerAdmin(@Valid @RequestBody AdminRequestDTO adminRequestDTO) {
        AdminResponseDTO response = authService.registerAdmin(adminRequestDTO);
        return ResponseEntity.ok(response);
    }
}
