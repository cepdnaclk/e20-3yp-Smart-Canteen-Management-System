//package com.SmartCanteen.Backend.Services;
//
//
//
//import com.SmartCanteen.Backend.DTOs.EmailRequestDTO;
//import com.SmartCanteen.Backend.DTOs.VerificationRequest;
//import com.SmartCanteen.Backend.Entities.VerificationCode;
//import com.SmartCanteen.Backend.Exceptions.GlobalExceptionHandler;
//import com.SmartCanteen.Backend.Repositories.VerificationCodeRepository;
//import lombok.RequiredArgsConstructor;
//import org.springframework.stereotype.Service;
//
//import java.time.LocalDateTime;
//import java.util.Optional;
//import java.util.Random;
//
//@Service
//@RequiredArgsConstructor
//public class VerificationService {
//    private final VerificationCodeRepository verificationCodeRepository;
//    private final EmailService emailService;
//
//    private static final int CODE_LENGTH = 4;
//    private static final int EXPIRATION_MINUTES = 5;
//
//    public void sendVerificationCode(EmailRequestDTO request) {
//        // Generate random 4-digit code
//        String code = generateRandomCode();
//
//        // Delete existing code if any
//        verificationCodeRepository.deleteByEmail(request.getEmail());
//
//        // Save new verification code
//        VerificationCode verificationCode = new VerificationCode();
//        verificationCode.setEmail(request.getEmail());
//        verificationCode.setCode(code);
//        verificationCode.setExpiresAt(LocalDateTime.now().plusMinutes(EXPIRATION_MINUTES));
//
//        verificationCodeRepository.save(verificationCode);
//
//        // Send email
//        emailService.sendVerificationEmail(request.getEmail(), code);
//    }
//
//    public void verifyCode(VerificationRequest request) {
//        Optional<VerificationCode> verificationCodeOpt =
//                verificationCodeRepository.findByEmail(request.getEmail());
//
//        if (verificationCodeOpt.isEmpty()) {
//            throw new GlobalExceptionHandler.InvalidVerificationCodeException("No verification code found for this email");
//        }
//
//        VerificationCode verificationCode = verificationCodeOpt.get();
//
//        // Check if code matches
//        if (!verificationCode.getCode().equals(request.getCode())) {
//            throw new GlobalExceptionHandler.InvalidVerificationCodeException("Invalid verification code");
//        }
//
//        // Check if code is expired
//        if (verificationCode.getExpiresAt().isBefore(LocalDateTime.now())) {
//            verificationCodeRepository.delete(verificationCode);
//            throw new GlobalExceptionHandler.VerificationCodeExpiredException("Verification code has expired");
//        }
//
//        // Code is valid - delete it
//        verificationCodeRepository.delete(verificationCode);
//    }
//
//    private String generateRandomCode() {
//        Random random = new Random();
//        int number = random.nextInt(9000) + 1000; // 1000-9999
//        return String.valueOf(number);
//    }
//}