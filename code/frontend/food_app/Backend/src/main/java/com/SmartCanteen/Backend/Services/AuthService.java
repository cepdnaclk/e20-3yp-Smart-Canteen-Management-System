//package com.SmartCanteen.Backend.Services;
//
//import com.SmartCanteen.Backend.DTOs.*;
//import com.SmartCanteen.Backend.Entities.*;
//import com.SmartCanteen.Backend.Repositories.*;
//import com.SmartCanteen.Backend.Security.JwtTokenProvider;
//import jakarta.mail.MessagingException;
//import lombok.RequiredArgsConstructor;
//import org.slf4j.Logger;
//import org.slf4j.LoggerFactory;
//import org.springframework.security.authentication.AuthenticationManager;
//import org.springframework.security.authentication.BadCredentialsException;
//import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
//import org.springframework.security.core.AuthenticationException;
//import org.springframework.security.crypto.password.PasswordEncoder;
//import org.springframework.stereotype.Service;
//import org.springframework.util.StringUtils;
//
//import java.math.BigDecimal;
//import java.time.LocalDateTime;
//import java.util.Random;
//
//@Service
//@RequiredArgsConstructor
//public class AuthService {
//
//    private final UserRepository userRepository;
//    private final AdminRepository adminRepository;
//    private final CustomerRepository customerRepository;
//    private final MerchantRepository merchantRepository;
//    private final TemporaryUserRepository temporaryUserRepository;
//    private final VerificationCodeRepository verificationCodeRepository;
//    private final EmailService emailService;
//
//    private final PasswordEncoder passwordEncoder;
//    private final JwtTokenProvider jwtTokenProvider;
//    private final AuthenticationManager authenticationManager;
//
//    private static final Logger log = LoggerFactory.getLogger(AuthService.class);
//
//    public AuthResponseDTO authenticateUser(LoginRequestDTO loginRequest) {
//        try {
//            authenticationManager.authenticate(
//                    new UsernamePasswordAuthenticationToken(loginRequest.getUsername(), loginRequest.getPassword()));
//        } catch (AuthenticationException ex) {
//            throw new BadCredentialsException("Invalid username or password");
//        }
//
//        User user = userRepository.findByUsername(loginRequest.getUsername())
//                .orElseThrow(() -> new BadCredentialsException("User not found"));
//
//        return getAuthResponseDTO(user);
//    }
//
//    public CustomerResponseDTO registerCustomer(CustomerRequestDTO dto) {
//        validateRequiredFields(dto.getUsername(), dto.getEmail(), dto.getPassword());
//
//        if (userRepository.existsByUsername(dto.getUsername()) || temporaryUserRepository.existsByEmail(dto.getEmail())) {
//            throw new RuntimeException("Username or email is already taken");
//        }
//
//        TemporaryUser tempUser = new TemporaryUser();
//        tempUser.setUsername(dto.getUsername());
//        tempUser.setEmail(dto.getEmail());
//        tempUser.setPassword(passwordEncoder.encode(dto.getPassword()));
//        tempUser.setFullName(dto.getFullName());
//        tempUser.setCardID(dto.getCardID());
//        tempUser.setFingerprintID(dto.getFingerprintID());
//        tempUser.setCreditBalance(dto.getCreditBalance() != null && dto.getCreditBalance().compareTo(BigDecimal.ZERO) >= 0
//                ? dto.getCreditBalance() : BigDecimal.ZERO);
//        tempUser.setRole(Role.CUSTOMER);
//        temporaryUserRepository.save(tempUser);
//
//        try {
//            String code = generateVerificationCode();
//            saveVerificationCode(dto.getEmail(), code);
//            emailService.sendVerificationCode(dto.getEmail(), code);
//        } catch (Exception e) {
//            temporaryUserRepository.delete(tempUser);
//            throw new RuntimeException("Failed to send verification code: " + e.getMessage());
//        }
//
//        CustomerResponseDTO response = new CustomerResponseDTO();
//        response.setUsername(dto.getUsername());
//        response.setEmail(dto.getEmail());
//        response.setFullName(dto.getFullName());
//        response.setCreditBalance(tempUser.getCreditBalance());
//        return response;
//    }
//
//    public MerchantResponseDTO registerMerchant(MerchantRequestDTO dto) {
//        validateRequiredFields(dto.getUsername(), dto.getEmail(), dto.getPassword());
//
//        if (!StringUtils.hasText(dto.getCanteenName())) {
//            throw new RuntimeException("Canteen name is required");
//        }
//
//        if (userRepository.existsByUsername(dto.getUsername()) || temporaryUserRepository.existsByEmail(dto.getEmail())) {
//            throw new RuntimeException("Username or email is already taken");
//        }
//
//        TemporaryUser tempUser = new TemporaryUser();
//        tempUser.setUsername(dto.getUsername());
//        tempUser.setEmail(dto.getEmail());
//        tempUser.setPassword(passwordEncoder.encode(dto.getPassword()));
//        tempUser.setCanteenName(dto.getCanteenName());
//        tempUser.setCardID(dto.getCardID());
//        tempUser.setFingerprintID(dto.getFingerprintID());
//        tempUser.setRole(Role.MERCHANT);
//        temporaryUserRepository.save(tempUser);
//
//        try {
//            String code = generateVerificationCode();
//            saveVerificationCode(dto.getEmail(), code);
//            emailService.sendVerificationCode(dto.getEmail(), code);
//        } catch (Exception e) {
//            temporaryUserRepository.delete(tempUser);
//            throw new RuntimeException("Failed to send verification code: " + e.getMessage());
//        }
//
//        MerchantResponseDTO response = new MerchantResponseDTO();
//        response.setUsername(dto.getUsername());
//        response.setEmail(dto.getEmail());
//        response.setCanteenName(dto.getCanteenName());
//        return response;
//    }
//
//    public AdminResponseDTO registerAdmin(AdminRequestDTO dto) {
//        validateRequiredFields(dto.getUsername(), dto.getEmail(), dto.getPassword());
//
//        if (userRepository.existsByUsername(dto.getUsername()) || temporaryUserRepository.existsByEmail(dto.getEmail())) {
//            throw new RuntimeException("Username or email is already taken");
//        }
//
//        TemporaryUser tempUser = new TemporaryUser();
//        tempUser.setUsername(dto.getUsername());
//        tempUser.setEmail(dto.getEmail());
//        tempUser.setPassword(passwordEncoder.encode(dto.getPassword()));
//        tempUser.setFullName(dto.getFullName());
//        tempUser.setCardID(dto.getCardID());
//        tempUser.setFingerprintID(dto.getFingerprintID());
//        tempUser.setRole(Role.ADMIN);
//        temporaryUserRepository.save(tempUser);
//
//        try {
//            String code = generateVerificationCode();
//            saveVerificationCode(dto.getEmail(), code);
//            emailService.sendVerificationCode(dto.getEmail(), code);
//        } catch (Exception e) {
//            temporaryUserRepository.delete(tempUser);
//            throw new RuntimeException("Failed to send verification code: " + e.getMessage());
//        }
//
//        AdminResponseDTO response = new AdminResponseDTO();
//        response.setUsername(dto.getUsername());
//        response.setEmail(dto.getEmail());
//        response.setFullName(dto.getFullName());
//        return response;
//    }
//
//    public AuthResponseDTO verifyEmail(VerifyEmailRequestDTO dto) {
//        String normalizedEmail = dto.getEmail();
//        log.info("Verifying email DTO: {}", dto);
//
//        System.out.println(dto.getEmail());
//
//        log.info("Verifying email:" + normalizedEmail);
//        VerificationCode verificationCode = verificationCodeRepository.findByEmail(dto.getEmail())
//                .orElseThrow(() -> new RuntimeException("Verification code not found"));
//
//        if (!verificationCode.getCode().equals(dto.getCode()) || verificationCode.getExpiresAt().isBefore(LocalDateTime.now())) {
//            throw new RuntimeException("Invalid or expired verification code");
//        }
//
//        TemporaryUser tempUser = temporaryUserRepository.findByEmail(dto.getEmail())
//                .orElseThrow(() -> new RuntimeException("Temporary user not found"));
//
//        User user;
//        switch (tempUser.getRole()) {
//            case CUSTOMER:
//                Customer customer = new Customer();
//                customer.setUsername(tempUser.getUsername());
//                customer.setEmail(tempUser.getEmail());
//                customer.setPassword(tempUser.getPassword());
//                customer.setFullName(tempUser.getFullName());
//                customer.setCardID(tempUser.getCardID());
//                customer.setFingerprintID(tempUser.getFingerprintID());
//                customer.setCreditBalance(tempUser.getCreditBalance());
//                customer.setRole(Role.CUSTOMER);
//                user = customerRepository.save(customer); // Automatically inserts into users + customers
//                break;
//
//            case MERCHANT:
//                Merchant merchant = new Merchant();
//                merchant.setUsername(tempUser.getUsername());
//                merchant.setEmail(tempUser.getEmail());
//                merchant.setPassword(tempUser.getPassword());
//                merchant.setCanteenName(tempUser.getCanteenName());
//                merchant.setCardID(tempUser.getCardID());
//                merchant.setFingerprintID(tempUser.getFingerprintID());
//                merchant.setRole(Role.MERCHANT);
//                user = merchantRepository.save(merchant);
//                break;
//            case ADMIN:
//                Admin admin = new Admin();
//                admin.setUsername(tempUser.getUsername());
//                admin.setEmail(tempUser.getEmail());
//                admin.setPassword(tempUser.getPassword());
//                admin.setFullName(tempUser.getFullName());
//                admin.setCardID(tempUser.getCardID());
//                admin.setFingerprintID(tempUser.getFingerprintID());
//                admin.setRole(Role.ADMIN);
//                user = adminRepository.save(admin);
//                break;
//            default:
//                throw new RuntimeException("Invalid user role");
//        }
//
//        temporaryUserRepository.delete(tempUser);
//        verificationCodeRepository.delete(verificationCode);
//
//        return getAuthResponseDTO(user);
//    }
//
//    private AuthResponseDTO getAuthResponseDTO(User user) {
//        String token = jwtTokenProvider.generateToken(user.getUsername(), user.getRole().name());
//
//        AuthResponseDTO response = new AuthResponseDTO();
//        response.setToken(token);
//        response.setUserId(user.getId());
//        response.setUsername(user.getUsername());
//        response.setRole(user.getRole().name());
//        return response;
//    }
//
//    public void resendVerificationCode(ResendCodeRequestDTO dto) throws MessagingException {
//        validateRequiredFields(null, dto.getEmail(), null);
//
//        TemporaryUser tempUser = temporaryUserRepository.findByEmail(dto.getEmail())
//                .orElseThrow(() -> new RuntimeException("Temporary user not found"));
//
//        String code = generateVerificationCode();
//        saveVerificationCode(dto.getEmail(), code);
//        emailService.sendVerificationCode(dto.getEmail(), code);
//    }
//
//    private String generateVerificationCode() {
//        Random random = new Random();
//        return String.format("%04d", random.nextInt(10000));
//    }
//
//    private void saveVerificationCode(String email, String code) {
//        VerificationCode verificationCode = verificationCodeRepository.findByEmail(email)
//                .orElse(new VerificationCode());
//        verificationCode.setEmail(email);
//        verificationCode.setCode(code);
//        verificationCode.setExpiresAt(LocalDateTime.now().plusMinutes(10));
//        verificationCodeRepository.save(verificationCode);
//    }
//
//    private void validateRequiredFields(String username, String email, String password) {
//        if (username != null && !StringUtils.hasText(username)) {
//            throw new RuntimeException("Username is required");
//        }
//        if (email != null && !StringUtils.hasText(email)) {
//            throw new RuntimeException("Email is required");
//        }
//        if (password != null && !StringUtils.hasText(password)) {
//            throw new RuntimeException("Password is required");
//        }
//        if (email != null && !email.matches("^[\\w-.]+@([\\w-]+\\.)+[\\w-]{2,4}$")) {
//            throw new RuntimeException("Invalid email format");
//        }
//    }
//}








package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.*;
import com.SmartCanteen.Backend.Entities.*;
import com.SmartCanteen.Backend.Repositories.*;
import com.SmartCanteen.Backend.Security.JwtTokenProvider;
import jakarta.mail.MessagingException;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Random;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final AdminRepository adminRepository;
    private final CustomerRepository customerRepository;
    private final MerchantRepository merchantRepository;
    private final TemporaryUserRepository temporaryUserRepository;
    private final VerificationCodeRepository verificationCodeRepository;
    private final EmailService emailService;

    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final AuthenticationManager authenticationManager;

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);
/*
    public AuthResponseDTO authenticateUser(LoginRequestDTO loginRequest) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword()));
        } catch (AuthenticationException ex) {
            throw new BadCredentialsException("Invalid username or password");
        }

        User user = userRepository.findByUsername(loginRequest.getEmail())
                .orElseThrow(() -> new BadCredentialsException("User not found"));

        return getAuthResponseDTO(user);
    }
*/
public AuthResponseDTO authenticateUser(LoginRequestDTO loginRequest) {
    try {
        // Authenticate using email as the principal
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword()));
    } catch (AuthenticationException ex) {
        throw new BadCredentialsException("Invalid email or password");
    }

    // Find user by email instead of username
    User user = userRepository.findByEmail(loginRequest.getEmail())
            .orElseThrow(() -> new BadCredentialsException("User not found"));

    return getAuthResponseDTO(user);
}

    public CustomerResponseDTO registerCustomer(CustomerRequestDTO dto) {
        validateRequiredFields(dto.getUsername(), dto.getEmail(), dto.getPassword());

        String normalizedEmail = dto.getEmail().trim().toLowerCase();

        if (userRepository.existsByUsername(dto.getUsername()) || temporaryUserRepository.existsByEmail(normalizedEmail)) {
            throw new RuntimeException("Username or email is already taken");
        }

        TemporaryUser tempUser = new TemporaryUser();
        tempUser.setUsername(dto.getUsername());
        tempUser.setEmail(normalizedEmail);
        tempUser.setPassword(passwordEncoder.encode(dto.getPassword()));
        tempUser.setFullName(dto.getFullName());
        tempUser.setCardID(dto.getCardID());
        tempUser.setFingerprintID(dto.getFingerprintID());
        tempUser.setCreditBalance(dto.getCreditBalance() != null && dto.getCreditBalance().compareTo(BigDecimal.ZERO) >= 0
                ? dto.getCreditBalance() : BigDecimal.ZERO);
        tempUser.setRole(Role.CUSTOMER);
        temporaryUserRepository.save(tempUser);

        try {
            String code = generateVerificationCode();
            saveVerificationCode(normalizedEmail, code);
            emailService.sendVerificationCode(normalizedEmail, code);
        } catch (Exception e) {
            temporaryUserRepository.delete(tempUser);
            throw new RuntimeException("Failed to send verification code: " + e.getMessage());
        }

        CustomerResponseDTO response = new CustomerResponseDTO();
        response.setUsername(dto.getUsername());
        response.setEmail(normalizedEmail);
        response.setFullName(dto.getFullName());
        response.setCreditBalance(tempUser.getCreditBalance());
        return response;
    }

    public MerchantResponseDTO registerMerchant(MerchantRequestDTO dto) {
        validateRequiredFields(dto.getUsername(), dto.getEmail(), dto.getPassword());

        if (!StringUtils.hasText(dto.getCanteenName())) {
            System.out.println(dto.getCanteenName());
            throw new RuntimeException("Canteen name is required");
        }

        String normalizedEmail = dto.getEmail().trim().toLowerCase();

        if (userRepository.existsByUsername(dto.getUsername()) || temporaryUserRepository.existsByEmail(normalizedEmail)) {
            throw new RuntimeException("Username or email is already taken");
        }

        TemporaryUser tempUser = new TemporaryUser();
        tempUser.setUsername(dto.getUsername());
        tempUser.setEmail(normalizedEmail);
        tempUser.setPassword(passwordEncoder.encode(dto.getPassword()));
        tempUser.setCanteenName(dto.getCanteenName());
        tempUser.setCardID(dto.getCardID());
        tempUser.setFingerprintID(dto.getFingerprintID());
        tempUser.setRole(Role.MERCHANT);
        temporaryUserRepository.save(tempUser);

        try {
            String code = generateVerificationCode();
            saveVerificationCode(normalizedEmail, code);
            emailService.sendVerificationCode(normalizedEmail, code);
        } catch (Exception e) {
            temporaryUserRepository.delete(tempUser);
            throw new RuntimeException("Failed to send verification code: " + e.getMessage());
        }

        MerchantResponseDTO response = new MerchantResponseDTO();
        response.setUsername(dto.getUsername());
        response.setEmail(normalizedEmail);
        response.setCanteenName(dto.getCanteenName());
        return response;
    }

    public AdminResponseDTO registerAdmin(AdminRequestDTO dto) {
        validateRequiredFields(dto.getUsername(), dto.getEmail(), dto.getPassword());

        String normalizedEmail = dto.getEmail().trim().toLowerCase();

        if (userRepository.existsByUsername(dto.getUsername()) || temporaryUserRepository.existsByEmail(normalizedEmail)) {
            throw new RuntimeException("Username or email is already taken");
        }

        TemporaryUser tempUser = new TemporaryUser();
        tempUser.setUsername(dto.getUsername());
        tempUser.setEmail(normalizedEmail);
        tempUser.setPassword(passwordEncoder.encode(dto.getPassword()));
        tempUser.setFullName(dto.getFullName());
        tempUser.setCardID(dto.getCardID());
        tempUser.setFingerprintID(dto.getFingerprintID());
        tempUser.setRole(Role.ADMIN);
        temporaryUserRepository.save(tempUser);

        try {
            String code = generateVerificationCode();
            saveVerificationCode(normalizedEmail, code);
            emailService.sendVerificationCode(normalizedEmail, code);
        } catch (Exception e) {
            temporaryUserRepository.delete(tempUser);
            throw new RuntimeException("Failed to send verification code: " + e.getMessage());
        }

        AdminResponseDTO response = new AdminResponseDTO();
        response.setUsername(dto.getUsername());
        response.setEmail(normalizedEmail);
        response.setFullName(dto.getFullName());
        return response;
    }

    public AuthResponseDTO verifyEmail(VerifyEmailRequestDTO dto) {
        // Normalize email
        String normalizedEmail = dto.getEmail().trim().toLowerCase();

        log.info("Verifying email: {}", normalizedEmail);
        VerificationCode verificationCode = verificationCodeRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new RuntimeException("Verification code not found"));

        if (!verificationCode.getCode().equals(dto.getCode()) || verificationCode.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("Invalid or expired verification code");
        }

        TemporaryUser tempUser = temporaryUserRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new RuntimeException("Temporary user not found"));

        User user;
        switch (tempUser.getRole()) {
            case CUSTOMER:
                Customer customer = new Customer();
                customer.setUsername(tempUser.getUsername());
                customer.setEmail(normalizedEmail);
                customer.setPassword(tempUser.getPassword());
                customer.setFullName(tempUser.getFullName());
                customer.setCardID(tempUser.getCardID());
                customer.setFingerprintID(tempUser.getFingerprintID());
                customer.setCreditBalance(tempUser.getCreditBalance());
                customer.setRole(Role.CUSTOMER);
                user = customerRepository.save(customer);
                break;
            case MERCHANT:
                Merchant merchant = new Merchant();
                merchant.setUsername(tempUser.getUsername());
                merchant.setEmail(normalizedEmail);
                merchant.setPassword(tempUser.getPassword());
                merchant.setCanteenName(tempUser.getCanteenName());
                merchant.setCardID(tempUser.getCardID());
                merchant.setFingerprintID(tempUser.getFingerprintID());
                merchant.setRole(Role.MERCHANT);
                user = merchantRepository.save(merchant);
                break;
            case ADMIN:
                Admin admin = new Admin();
                admin.setUsername(tempUser.getUsername());
                admin.setEmail(normalizedEmail);
                admin.setPassword(tempUser.getPassword());
                admin.setFullName(tempUser.getFullName());
                admin.setCardID(tempUser.getCardID());
                admin.setFingerprintID(tempUser.getFingerprintID());
                admin.setRole(Role.ADMIN);
                user = adminRepository.save(admin);
                break;
            default:
                throw new RuntimeException("Invalid user role");
        }

        temporaryUserRepository.delete(tempUser);
        verificationCodeRepository.delete(verificationCode);

        return getAuthResponseDTO(user);
    }

    private AuthResponseDTO getAuthResponseDTO(User user) {
        String token = jwtTokenProvider.generateToken(user.getUsername(), user.getRole().name());

        AuthResponseDTO response = new AuthResponseDTO();
        response.setToken(token);
        response.setUserId(user.getId());
        response.setUsername(user.getUsername());
        response.setRole(user.getRole().name());
        return response;
    }

    public void resendVerificationCode(ResendCodeRequestDTO dto) throws MessagingException {
        validateRequiredFields(null, dto.getEmail(), null);

        String normalizedEmail = dto.getEmail().trim().toLowerCase();

        TemporaryUser tempUser = temporaryUserRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new RuntimeException("Temporary user not found"));

        String code = generateVerificationCode();
        saveVerificationCode(normalizedEmail, code);
        emailService.sendVerificationCode(normalizedEmail, code);
    }

    @SuppressWarnings("DefaultLocale")
    private String generateVerificationCode() {
        Random random = new Random();
        return String.format("%04d", random.nextInt(10000));
    }

    private void saveVerificationCode(String email, String code) {
        VerificationCode verificationCode = verificationCodeRepository.findByEmail(email)
                .orElse(new VerificationCode());
        verificationCode.setEmail(email);
        verificationCode.setCode(code);
        verificationCode.setExpiresAt(LocalDateTime.now().plusMinutes(10));
        verificationCodeRepository.save(verificationCode);
    }

    private void validateRequiredFields(String username, String email, String password) {
        if (username != null && !StringUtils.hasText(username)) {
            throw new RuntimeException("Username is required");
        }
        if (email != null && !StringUtils.hasText(email)) {
            throw new RuntimeException("Email is required");
        }
        if (password != null && !StringUtils.hasText(password)) {
            throw new RuntimeException("Password is required");
        }
        if (email != null && !email.matches("^[\\w-.]+@([\\w-]+\\.)+[\\w-]{2,4}$")) {
            throw new RuntimeException("Invalid email format");
        }
    }
}
