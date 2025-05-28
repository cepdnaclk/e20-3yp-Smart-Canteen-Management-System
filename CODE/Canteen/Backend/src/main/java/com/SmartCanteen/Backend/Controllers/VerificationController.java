//package com.SmartCanteen.Backend.Controllers;
//
//
//
//import com.SmartCanteen.Backend.DTOs.EmailRequestDTO;
//import com.SmartCanteen.Backend.DTOs.VerificationRequest;
//import com.SmartCanteen.Backend.Services.VerificationService;
//import lombok.RequiredArgsConstructor;
//import org.springframework.http.ResponseEntity;
//import org.springframework.web.bind.annotation.PostMapping;
//import org.springframework.web.bind.annotation.RequestBody;
//import org.springframework.web.bind.annotation.RequestMapping;
//import org.springframework.web.bind.annotation.RestController;
//
//@RestController
//@RequestMapping("/api/verification")
//@RequiredArgsConstructor
//public class VerificationController {
//    private final VerificationService verificationService;
//
//    @PostMapping("/send-code")
//    public ResponseEntity<?> sendVerificationCode(@RequestBody EmailRequestDTO request) {
//        verificationService.sendVerificationCode(request);
//        return ResponseEntity.ok().body("Verification code sent successfully");
//    }
//
//    @PostMapping("/verify-code")
//    public ResponseEntity<?> verifyCode(@RequestBody VerificationRequest request) {
//        verificationService.verifyCode(request);
//        return ResponseEntity.ok().body("Email verified successfully");
//    }
//}