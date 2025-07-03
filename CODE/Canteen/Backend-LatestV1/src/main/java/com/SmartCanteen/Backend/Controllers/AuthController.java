//package com.SmartCanteen.Backend.Controllers;
//
//import com.SmartCanteen.Backend.DTOs.*;
//import com.SmartCanteen.Backend.Services.AuthService;
//import com.SmartCanteen.Backend.Services.EmailService;
//import jakarta.mail.MessagingException;
//import jakarta.validation.Valid;
//import lombok.RequiredArgsConstructor;
//import org.slf4j.Logger;
//import org.slf4j.LoggerFactory;
//import org.springframework.http.ResponseEntity;
//import org.springframework.util.StringUtils;
//import org.springframework.web.bind.annotation.*;
//
//@CrossOrigin(origins="*")
//@RestController
//@RequestMapping("/api/auth")
//@RequiredArgsConstructor
//public class AuthController {
//
//    private static final Logger log = LoggerFactory.getLogger(EmailService.class);
//
//
//    private final AuthService authService;
//
//    @PostMapping("/login")
//    public ResponseEntity<AuthResponseDTO> login(@RequestBody LoginRequestDTO loginRequest) {
//        AuthResponseDTO response = authService.authenticateUser(loginRequest);
//        return ResponseEntity.ok(response);
//    }
//
//    @PostMapping("/register/customer")
//    public ResponseEntity<CustomerResponseDTO> registerCustomer(@Valid @RequestBody CustomerRequestDTO customerRequestDTO) {
//        CustomerResponseDTO response = authService.registerCustomer(customerRequestDTO);
//        return ResponseEntity.ok(response);
//    }
//
//    @PostMapping("/register/merchant")
//    public ResponseEntity<MerchantResponseDTO> registerMerchant(@Valid @RequestBody MerchantRequestDTO merchantRequestDTO) {
//        MerchantResponseDTO response = authService.registerMerchant(merchantRequestDTO);
//        return ResponseEntity.ok(response);
//    }
//
//    @PostMapping("/register/admin")
//    public ResponseEntity<AdminResponseDTO> registerAdmin(@Valid @RequestBody AdminRequestDTO adminRequestDTO) {
//        AdminResponseDTO response = authService.registerAdmin(adminRequestDTO);
//        return ResponseEntity.ok(response);
//    }
//    @PostMapping("/verify-email")
//    public ResponseEntity<?> verifyEmail(@Valid @RequestBody VerifyEmailRequestDTO dto) {
//        try {
//            AuthResponseDTO response = authService.verifyEmail(dto);
//            log.info("Email verified successfully: {}", dto.getEmail());
//            return ResponseEntity.ok(response);
//        } catch (IllegalArgumentException e) {
//            log.warn("Client error during verification for {}: {}", dto.getEmail(), e.getMessage());
//            return ResponseEntity.badRequest().body(e.getMessage());
//        } catch (RuntimeException e) {
//            log.error("Server error during verification for {}: {}", dto.getEmail(), e.getMessage());
//            return ResponseEntity.internalServerError().body("Verification process failed");
//        }
//    }
//
//    @PostMapping("/resend-code")
//    public ResponseEntity<String> resendCode(@RequestBody ResendCodeRequestDTO dto) throws MessagingException {
//        authService.resendVerificationCode(dto);
//        return ResponseEntity.ok("Verification code resent successfully");
//    }
//
//    @PostMapping("/login/rfid")
//    public ResponseEntity<AuthResponseDTO> loginWithRFID(@RequestBody RFIDLoginRequestDTO request) {
//        AuthResponseDTO response = authService.authenticateWithCardID(request.getCardID());
//        return ResponseEntity.ok(response);
//    }
//
//
//
//}

package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.*;
import com.SmartCanteen.Backend.Services.AuthService;
import jakarta.mail.MessagingException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@CrossOrigin(origins="*")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private static final Logger log = LoggerFactory.getLogger(AuthController.class);

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponseDTO> login(@Valid @RequestBody LoginRequestDTO loginRequest) {
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

    @PostMapping("/verify-email")
    public ResponseEntity<?> verifyEmail(@Valid @RequestBody VerifyEmailRequestDTO dto) {
        AuthResponseDTO response = authService.verifyEmail(dto);
        log.info("Email verified successfully: {}", dto.getEmail());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/resend-code")
    public ResponseEntity<?> resendCode(@RequestBody ResendCodeRequestDTO dto) throws MessagingException {
        authService.resendVerificationCode(dto);
        return ResponseEntity.ok(Map.of("message", "Verification code resent successfully"));
    }

    @PostMapping("/login/rfid")
    public ResponseEntity<AuthResponseDTO> loginWithRFID(@RequestBody RFIDLoginRequestDTO request) {
        AuthResponseDTO response = authService.authenticateWithCardID(request.getCardID());
        return ResponseEntity.ok(response);
    }

    // --- NEW: FORGOT PASSWORD FUNCTIONALITY ---

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(@RequestBody EmailRequestDTO emailRequest) {
        authService.initiatePasswordReset(emailRequest.getEmail());
        return ResponseEntity.ok(Map.of("message", "Password reset link has been sent to your email."));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(@RequestBody PasswordResetRequestDTO resetRequest) {
        authService.finalizePasswordReset(resetRequest.getToken(), resetRequest.getNewPassword());
        return ResponseEntity.ok(Map.of("message", "Your password has been reset successfully."));
    }
}