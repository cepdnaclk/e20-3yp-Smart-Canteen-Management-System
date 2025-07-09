/*package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.*;
import com.SmartCanteen.Backend.Services.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
@CrossOrigin(origins="*")
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
    public ResponseEntity<CustomerResponseDTO> registerCustomer(@RequestBody CustomerRequestDTO customerRequestDTO) {
        CustomerResponseDTO response = authService.registerCustomer(customerRequestDTO);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register/merchant")
    public ResponseEntity<MerchantResponseDTO> registerMerchant(@Valid @RequestBody MerchantRequestDTO merchantRequestDTO) {
        MerchantResponseDTO response = authService.registerMerchant(merchantRequestDTO);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register/admin")
    public ResponseEntity<AdminResponseDTO> registerAdmin(@RequestBody AdminRequestDTO adminRequestDTO) {
        AdminResponseDTO response = authService.registerAdmin(adminRequestDTO);
        return ResponseEntity.ok(response);
    }
}
*/
package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.*;
import com.SmartCanteen.Backend.Services.AuthService;
import com.SmartCanteen.Backend.Services.EmailService;
import jakarta.mail.MessagingException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins="*")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);


    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponseDTO> login(@RequestBody LoginRequestDTO loginRequest) {
        return ResponseEntity.ok(authService.authenticateUser(loginRequest));
    }

    @PostMapping("/register/customer")
    public ResponseEntity<CustomerResponseDTO> registerCustomer(@RequestBody CustomerRequestDTO dto) {
        return ResponseEntity.ok(authService.registerCustomer(dto));
    }

    @PostMapping("/register/merchant")
    public ResponseEntity<MerchantResponseDTO> registerMerchant(@RequestBody MerchantRequestDTO dto) {
        return ResponseEntity.ok(authService.registerMerchant(dto));
    }

    @PostMapping("/register/admin")
    public ResponseEntity<AdminResponseDTO> registerAdmin(@RequestBody AdminRequestDTO dto) {
        return ResponseEntity.ok(authService.registerAdmin(dto));
    }
/*
    @PostMapping("/verify-email")
    public ResponseEntity<?> verifyEmail(@RequestBody VerifyEmailRequestDTO dto) {
        if (dto == null || !StringUtils.hasText(dto.getEmail()) || !StringUtils.hasText(dto.getCode())) {
            log.error("Invalid verification request: email or code missing");
            return ResponseEntity.badRequest().body("Email and code are required");
        }
        try {
            AuthResponseDTO response = authService.verifyEmail(dto);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            log.error("Verification failed: {}", e.getMessage());
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (RuntimeException e) {
            log.error("Verification failed for email: {}, error: {}", dto.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().body("Invalid or expired verification code");
        }
    }


*/

    @PostMapping("/verify-email")
    public ResponseEntity<?> verifyEmail(@Valid @RequestBody VerifyEmailRequestDTO dto) {
        try {
            AuthResponseDTO response = authService.verifyEmail(dto);
            log.info("Email verified successfully: {}", dto.getEmail());
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            log.warn("Client error during verification for {}: {}", dto.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (RuntimeException e) {
            log.error("Server error during verification for {}: {}", dto.getEmail(), e.getMessage());
            return ResponseEntity.internalServerError().body("Verification process failed");
        }
    }

    @PostMapping("/resend-code")
    public ResponseEntity<String> resendCode(@RequestBody ResendCodeRequestDTO dto) throws MessagingException {
        authService.resendVerificationCode(dto);
        return ResponseEntity.ok("Verification code resent successfully");
    }
}