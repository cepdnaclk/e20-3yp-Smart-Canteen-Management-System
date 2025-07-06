//package com.SmartCanteen.Backend.Services;
//
//import com.SmartCanteen.Backend.DTOs.*;
//import com.SmartCanteen.Backend.Entities.*;
//import com.SmartCanteen.Backend.Repositories.*;
//import com.SmartCanteen.Backend.Security.JwtTokenProvider;
//import com.SmartCanteen.Backend.Security.UserPrincipal;
//import jakarta.mail.MessagingException;
//import lombok.RequiredArgsConstructor;
//import org.slf4j.Logger;
//import org.slf4j.LoggerFactory;
//import org.springframework.security.authentication.AuthenticationManager;
//import org.springframework.security.authentication.BadCredentialsException;
//import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
//import org.springframework.security.core.AuthenticationException;
//import org.springframework.security.core.userdetails.UserDetails;
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
//    private final UserRepository userRepository;
//    private final AdminRepository adminRepository;
//    private final CustomerRepository customerRepository;
//    private final MerchantRepository merchantRepository;
//    private final TemporaryUserRepository temporaryUserRepository;
//    private final VerificationCodeRepository verificationCodeRepository;
//    private final EmailService emailService;
//    private final PasswordEncoder passwordEncoder;
//    private final JwtTokenProvider jwtTokenProvider;
//    private final AuthenticationManager authenticationManager;
//    private static final Logger log = LoggerFactory.getLogger(AuthService.class);
//
//    public AuthResponseDTO authenticateUser(LoginRequestDTO loginRequest) {
//        try {
//            authenticationManager.authenticate(
//                    new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword())
//            );
//        } catch (AuthenticationException ex) {
//            throw new BadCredentialsException("Invalid Email or password");
//        }
//        User user = userRepository.findByEmail(loginRequest.getEmail())
//                .orElseThrow(() -> new BadCredentialsException("User not found"));
//        return getAuthResponseDTO(user);
//    }
//
//    public CustomerResponseDTO registerCustomer(CustomerRequestDTO dto) {
//        validateRequiredFields(dto.getUsername(), dto.getEmail(), dto.getPassword());
//        String normalizedEmail = dto.getEmail().trim().toLowerCase();
//        if (userRepository.existsByUsername(dto.getUsername())) {
//            throw new UsernameAlreadyExistsException("Username is already taken");
//        }
//        if (temporaryUserRepository.existsByEmail(normalizedEmail)) {
//            throw new EmailAlreadyExistsException("Email is already registered and awaiting verification");
//        }
//        TemporaryUser tempUser = new TemporaryUser();
//        tempUser.setUsername(dto.getUsername());
//        tempUser.setEmail(normalizedEmail);
//        tempUser.setPassword(passwordEncoder.encode(dto.getPassword()));
//        tempUser.setFullName(dto.getFullName());
//        tempUser.setCardID(dto.getCardID());
//        tempUser.setFingerprintID(dto.getFingerprintID());
//        tempUser.setCreditBalance(dto.getCreditBalance() != null && dto.getCreditBalance().compareTo((double) 0) >= 0
//                ? BigDecimal.valueOf(dto.getCreditBalance()) : BigDecimal.ZERO);
//        tempUser.setRole(Role.CUSTOMER);
//        temporaryUserRepository.save(tempUser);
//        try {
//            String code = generateVerificationCode();
//            saveVerificationCode(normalizedEmail, code);
//            emailService.sendVerificationCode(normalizedEmail, code);
//        } catch (Exception e) {
//            temporaryUserRepository.delete(tempUser);
//            throw new RuntimeException("Failed to send verification code: " + e.getMessage());
//        }
//        CustomerResponseDTO response = new CustomerResponseDTO();
//        response.setUsername(dto.getUsername());
//        response.setEmail(normalizedEmail);
//        response.setFullName(dto.getFullName());
//        response.setCreditBalance(tempUser.getCreditBalance());
//        return response;
//    }
//
//    public MerchantResponseDTO registerMerchant(MerchantRequestDTO dto) {
//        validateRequiredFields(dto.getUsername(), dto.getEmail(), dto.getPassword());
//        if (!StringUtils.hasText(dto.getCanteenName())) {
//            throw new RuntimeException("Canteen name is required");
//        }
//        String normalizedEmail = dto.getEmail().trim().toLowerCase();
//        if (userRepository.existsByUsername(dto.getUsername())) {
//            throw new UsernameAlreadyExistsException("Username is already taken");
//        }
//        if (temporaryUserRepository.existsByEmail(normalizedEmail)) {
//            throw new EmailAlreadyExistsException("Email is already registered and awaiting verification");
//        }
//        TemporaryUser tempUser = new TemporaryUser();
//        tempUser.setUsername(dto.getUsername());
//        tempUser.setEmail(normalizedEmail);
//        tempUser.setPassword(passwordEncoder.encode(dto.getPassword()));
//        tempUser.setCanteenName(dto.getCanteenName());
//        tempUser.setCardID(dto.getCardID());
//        tempUser.setFingerprintID(dto.getFingerprintID());
//        tempUser.setRole(Role.MERCHANT);
//        temporaryUserRepository.save(tempUser);
//        try {
//            String code = generateVerificationCode();
//            saveVerificationCode(normalizedEmail, code);
//            emailService.sendVerificationCode(normalizedEmail, code);
//        } catch (Exception e) {
//            temporaryUserRepository.delete(tempUser);
//            throw new RuntimeException("Failed to send verification code: " + e.getMessage());
//        }
//        MerchantResponseDTO response = new MerchantResponseDTO();
//        response.setUsername(dto.getUsername());
//        response.setEmail(normalizedEmail);
//        response.setCanteenName(dto.getCanteenName());
//        return response;
//    }
//
//    public AdminResponseDTO registerAdmin(AdminRequestDTO dto) {
//        validateRequiredFields(dto.getUsername(), dto.getEmail(), dto.getPassword());
//        String normalizedEmail = dto.getEmail().trim().toLowerCase();
//        if (userRepository.existsByUsername(dto.getUsername())) {
//            throw new UsernameAlreadyExistsException("Username is already taken");
//        }
//        if (temporaryUserRepository.existsByEmail(normalizedEmail)) {
//            throw new EmailAlreadyExistsException("Email is already registered and awaiting verification");
//        }
//        TemporaryUser tempUser = new TemporaryUser();
//        tempUser.setUsername(dto.getUsername());
//        tempUser.setEmail(normalizedEmail);
//        tempUser.setPassword(passwordEncoder.encode(dto.getPassword()));
//        tempUser.setFullName(dto.getFullName());
//        tempUser.setCardID(dto.getCardID());
//        tempUser.setFingerprintID(dto.getFingerprintID());
//        tempUser.setRole(Role.ADMIN);
//        temporaryUserRepository.save(tempUser);
//        try {
//            String code = generateVerificationCode();
//            saveVerificationCode(normalizedEmail, code);
//            emailService.sendVerificationCode(normalizedEmail, code);
//        } catch (Exception e) {
//            temporaryUserRepository.delete(tempUser);
//            throw new RuntimeException("Failed to send verification code: " + e.getMessage());
//        }
//        AdminResponseDTO response = new AdminResponseDTO();
//        response.setUsername(dto.getUsername());
//        response.setEmail(normalizedEmail);
//        response.setFullName(dto.getFullName());
//        return response;
//    }
//
//    public AuthResponseDTO verifyEmail(VerifyEmailRequestDTO dto) {
//        String normalizedEmail = dto.getEmail().trim().toLowerCase();
//        log.info("Verifying email: {}", normalizedEmail);
//        VerificationCode verificationCode = verificationCodeRepository.findByEmail(normalizedEmail)
//                .orElseThrow(() -> new VerificationCodeException("Verification code not found"));
//        if (!verificationCode.getCode().equals(dto.getCode()) || verificationCode.getExpiresAt().isBefore(LocalDateTime.now())) {
//            throw new VerificationCodeException("Invalid or expired verification code");
//        }
//        TemporaryUser tempUser = temporaryUserRepository.findByEmail(normalizedEmail)
//                .orElseThrow(() -> new RuntimeException("Temporary user not found"));
//        User user;
//        switch (tempUser.getRole()) {
//            case CUSTOMER:
//                Customer customer = new Customer();
//                customer.setUsername(tempUser.getUsername());
//                customer.setEmail(normalizedEmail);
//                customer.setPassword(tempUser.getPassword());
//                customer.setFullName(tempUser.getFullName());
//                customer.setCardID(tempUser.getCardID());
//                customer.setFingerprintID(tempUser.getFingerprintID());
//                customer.setCreditBalance(tempUser.getCreditBalance());
//                customer.setRole(Role.CUSTOMER);
//                user = customerRepository.save(customer);
//                break;
//            case MERCHANT:
//                Merchant merchant = new Merchant();
//                merchant.setUsername(tempUser.getUsername());
//                merchant.setEmail(normalizedEmail);
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
//                admin.setEmail(normalizedEmail);
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
//        temporaryUserRepository.delete(tempUser);
//        verificationCodeRepository.delete(verificationCode);
//        return getAuthResponseDTO(user);
//    }
//
//    public void resendVerificationCode(ResendCodeRequestDTO dto) throws MessagingException {
//        validateRequiredFields(null, dto.getEmail(), null);
//        String normalizedEmail = dto.getEmail().trim().toLowerCase();
//        TemporaryUser tempUser = temporaryUserRepository.findByEmail(normalizedEmail)
//                .orElseThrow(() -> new RuntimeException("Temporary user not found"));
//        String code = generateVerificationCode();
//        saveVerificationCode(normalizedEmail, code);
//        emailService.sendVerificationCode(normalizedEmail, code);
//    }
//
//    private AuthResponseDTO getAuthResponseDTO(User user) {
//        String token = jwtTokenProvider.generateToken(user.getEmail(), user.getRole().name());
//        System.out.println("This is the email: 11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111 " + user.getEmail());
//        AuthResponseDTO response = new AuthResponseDTO();
//        response.setToken(token);
//        response.setUserId(user.getId());
//        response.setUsername(user.getUsername());
//        response.setRole(user.getRole().name());
//        response.setEmail(user.getEmail());
//        return response;
//    }
//
//    @SuppressWarnings("DefaultLocale")
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
//            throw new UsernameAlreadyExistsException("Username is required");
//        }
//        if (email != null && !StringUtils.hasText(email)) {
//            throw new EmailAlreadyExistsException("Email is required");
//        }
//        if (password != null && !StringUtils.hasText(password)) {
//            throw new RuntimeException("Password is required");
//        }
//        if (email != null && !email.matches("^[\\w-.]+@([\\w-]+\\.)+[\\w-]{2,4}$")) {
//            throw new EmailAlreadyExistsException("Invalid email format");
//        }
//    }
//
//    public static class UsernameAlreadyExistsException extends RuntimeException {
//        public UsernameAlreadyExistsException(String message) { super(message); }
//    }
//    public static class EmailAlreadyExistsException extends RuntimeException {
//        public EmailAlreadyExistsException(String message) { super(message); }
//    }
//    public static class VerificationCodeException extends RuntimeException {
//        public VerificationCodeException(String message) { super(message); }
//    }
//
//    public Long getUserIdFromUserDetails(UserDetails userDetails) {
//        if (userDetails instanceof UserPrincipal) {
//            return ((UserPrincipal) userDetails).getId();
//        }
//        throw new RuntimeException("User ID not found in UserDetails");
//    }
//
//    public AuthResponseDTO authenticateWithCardID(String cardID) {
//        if (!StringUtils.hasText(cardID)) {
//            throw new RuntimeException("Card ID is required");
//        }
//
//        User user = userRepository.findByCardID(cardID)
//                .orElseThrow(() -> new BadCredentialsException("Invalid Card ID"));
//
//        return getAuthResponseDTO(user);
//    }
//}


package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.*;
import com.SmartCanteen.Backend.Entities.*;
import com.SmartCanteen.Backend.Exceptions.ResourceNotFoundException;
import com.SmartCanteen.Backend.Repositories.*;
import com.SmartCanteen.Backend.Security.JwtTokenProvider;
import com.SmartCanteen.Backend.Security.UserPrincipal;
import jakarta.mail.MessagingException;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Random;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final AdminRepository adminRepository;
    private final CustomerRepository customerRepository;
    private final MerchantRepository merchantRepository;
    private final TemporaryUserRepository temporaryUserRepository;
    private final VerificationCodeRepository verificationCodeRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final AuthenticationManager authenticationManager;
    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    @Transactional
    public AuthResponseDTO authenticateUser(LoginRequestDTO loginRequest) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword())
            );
        } catch (AuthenticationException ex) {
            log.warn("Authentication failed for email: {}", loginRequest.getEmail());
            throw new BadCredentialsException("Invalid email or password");
        }
        User user = userRepository.findByEmail(loginRequest.getEmail())
                .orElseThrow(() -> new BadCredentialsException("User not found with email: " + loginRequest.getEmail()));
        return getAuthResponseDTO(user);
    }

    @Transactional
    public CustomerResponseDTO registerCustomer(CustomerRequestDTO dto) {
        TemporaryUser tempUser = createTemporaryUser(dto.getUsername(), dto.getEmail(), dto.getPassword(), Role.CUSTOMER);
        tempUser.setFullName(dto.getFullName());
        tempUser.setCardID(dto.getCardID());
        tempUser.setFingerprintID(dto.getFingerprintID());
        tempUser.setCreditBalance(dto.getCreditBalance() != null && dto.getCreditBalance() >= 0
                ? BigDecimal.valueOf(dto.getCreditBalance()) : BigDecimal.ZERO);

        temporaryUserRepository.save(tempUser);
        sendVerificationEmail(tempUser.getEmail());

        CustomerResponseDTO response = new CustomerResponseDTO();
        response.setUsername(dto.getUsername());
        response.setEmail(tempUser.getEmail());
        response.setFullName(dto.getFullName());
        response.setCreditBalance(tempUser.getCreditBalance());
        return response;
    }

    @Transactional
    public MerchantResponseDTO registerMerchant(MerchantRequestDTO dto) {
        if (!StringUtils.hasText(dto.getCanteenName())) {
            throw new IllegalArgumentException("Canteen name is required");
        }
        TemporaryUser tempUser = createTemporaryUser(dto.getUsername(), dto.getEmail(), dto.getPassword(), Role.MERCHANT);
        tempUser.setCanteenName(dto.getCanteenName());
        tempUser.setCardID(dto.getCardID());
        tempUser.setFingerprintID(dto.getFingerprintID());

        temporaryUserRepository.save(tempUser);
        sendVerificationEmail(tempUser.getEmail());

        MerchantResponseDTO response = new MerchantResponseDTO();
        response.setUsername(dto.getUsername());
        response.setEmail(tempUser.getEmail());
        response.setCanteenName(dto.getCanteenName());
        return response;
    }

    @Transactional
    public AdminResponseDTO registerAdmin(AdminRequestDTO dto) {
        TemporaryUser tempUser = createTemporaryUser(dto.getUsername(), dto.getEmail(), dto.getPassword(), Role.ADMIN);
        tempUser.setFullName(dto.getFullName());
        tempUser.setCardID(dto.getCardID());
        tempUser.setFingerprintID(dto.getFingerprintID());

        temporaryUserRepository.save(tempUser);
        sendVerificationEmail(tempUser.getEmail());

        AdminResponseDTO response = new AdminResponseDTO();
        response.setUsername(dto.getUsername());
        response.setEmail(tempUser.getEmail());
        response.setFullName(dto.getFullName());
        return response;
    }

    private TemporaryUser createTemporaryUser(String username, String email, String password, Role role) {
        validateRequiredFields(username, email, password);
        String normalizedEmail = email.trim().toLowerCase();
        if (userRepository.existsByEmail(normalizedEmail) || temporaryUserRepository.existsByEmail(normalizedEmail)) {
            throw new EmailAlreadyExistsException("Email is already in use.");
        }
        if (userRepository.existsByUsername(username)) {
            throw new UsernameAlreadyExistsException("Username is already taken.");
        }
        TemporaryUser tempUser = new TemporaryUser();
        tempUser.setUsername(username);
        tempUser.setEmail(normalizedEmail);
        tempUser.setPassword(passwordEncoder.encode(password));
        tempUser.setRole(role);
        return tempUser;
    }

    private void sendVerificationEmail(String email) {
        try {
            String code = generateVerificationCode();
            saveVerificationCode(email, code);
            emailService.sendVerificationCode(email, code);
        } catch (MessagingException e) {
            log.error("Failed to send verification email to {}", email, e);
            throw new RuntimeException("Failed to send verification code. Please try again later.");
        }
    }

    @Transactional
    public AuthResponseDTO verifyEmail(VerifyEmailRequestDTO dto) {
        String normalizedEmail = dto.getEmail().trim().toLowerCase();
        log.info("Verifying email: {}", normalizedEmail);

        VerificationCode verificationCode = verificationCodeRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new VerificationCodeException("Verification code not found. Please request a new one."));

        if (!verificationCode.getCode().equals(dto.getCode())) {
            throw new VerificationCodeException("Invalid verification code.");
        }
        if (verificationCode.getExpiresAt().isBefore(LocalDateTime.now())) {
            verificationCodeRepository.delete(verificationCode);
            throw new VerificationCodeException("Verification code has expired. Please request a new one.");
        }

        TemporaryUser tempUser = temporaryUserRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new ResourceNotFoundException("Temporary user not found. Please register again."));

        User user = persistUserFromTemporary(tempUser);

        temporaryUserRepository.delete(tempUser);
        verificationCodeRepository.delete(verificationCode);

        return getAuthResponseDTO(user);
    }

    private User persistUserFromTemporary(TemporaryUser tempUser) {
        User user;
        switch (tempUser.getRole()) {
            case CUSTOMER -> {
                Customer customer = new Customer();
                customer.setCreditBalance(tempUser.getCreditBalance());
                user = customer;
            }
            case MERCHANT -> {
                Merchant merchant = new Merchant();
                merchant.setCanteenName(tempUser.getCanteenName());
                user = merchant;
            }
            case ADMIN -> user = new Admin();
            default -> throw new IllegalStateException("Invalid user role during registration: " + tempUser.getRole());
        }

        user.setUsername(tempUser.getUsername());
        user.setEmail(tempUser.getEmail());
        user.setPassword(tempUser.getPassword());
        user.setFullName(tempUser.getFullName());
        user.setCardID(tempUser.getCardID());
        user.setFingerprintID(tempUser.getFingerprintID());
        user.setRole(tempUser.getRole());

        return userRepository.save(user);
    }


    @Transactional
    public void resendVerificationCode(ResendCodeRequestDTO dto) throws MessagingException {
        String normalizedEmail = dto.getEmail().trim().toLowerCase();
        if (!temporaryUserRepository.existsByEmail(normalizedEmail)) {
            throw new ResourceNotFoundException("No pending registration found for this email.");
        }
        sendVerificationEmail(normalizedEmail);
    }

    @Transactional
    public AuthResponseDTO authenticateWithCardID(String cardID) {
        if (!StringUtils.hasText(cardID)) {
            throw new IllegalArgumentException("Card ID must be provided.");
        }
        User user = userRepository.findByCardID(cardID)
                .orElseThrow(() -> new BadCredentialsException("Invalid Card ID. No user found."));
        return getAuthResponseDTO(user);
    }

    @Transactional
    public void initiatePasswordReset(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("No user found with that email address."));

        String token = UUID.randomUUID().toString();
        PasswordResetToken resetToken = new PasswordResetToken();
        resetToken.setToken(token);
        resetToken.setUser(user);
        resetToken.setExpiryDate(LocalDateTime.now().plusHours(1));
        passwordResetTokenRepository.save(resetToken);

        try {
            emailService.sendPasswordResetEmail(email, token);
        } catch (MessagingException e) {
            log.error("Failed to send password reset email to {}", email, e);
            throw new RuntimeException("Error sending password reset email.");
        }
    }

    @Transactional
    public void finalizePasswordReset(String token, String newPassword) {
        PasswordResetToken resetToken = passwordResetTokenRepository.findByToken(token)
                .orElseThrow(() -> new ResourceNotFoundException("Invalid password reset token."));

        if (resetToken.getExpiryDate().isBefore(LocalDateTime.now())) {
            passwordResetTokenRepository.delete(resetToken);
            throw new IllegalArgumentException("Password reset token has expired.");
        }

        if (!StringUtils.hasText(newPassword) || newPassword.length() < 6) {
            throw new IllegalArgumentException("Password must be at least 6 characters long.");
        }

        User user = resetToken.getUser();
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        passwordResetTokenRepository.delete(resetToken);
        log.info("Password successfully reset for user: {}", user.getEmail());
    }

    // --- FIX: ADDED THE MISSING HELPER METHOD ---
    public Long getUserIdFromUserDetails(UserDetails userDetails) {
        if (userDetails instanceof UserPrincipal) {
            return ((UserPrincipal) userDetails).getId();
        }
        throw new IllegalArgumentException("UserDetails object is not an instance of UserPrincipal, cannot extract user ID.");
    }

    private AuthResponseDTO getAuthResponseDTO(User user) {
        String token = jwtTokenProvider.generateToken(user.getEmail(), user.getRole().name());
        AuthResponseDTO response = new AuthResponseDTO();
        response.setToken(token);
        response.setUserId(user.getId());
        response.setUsername(user.getUsername());
        response.setRole(user.getRole().name());
        response.setEmail(user.getEmail());
        return response;
    }

    private String generateVerificationCode() {
        return String.format("%04d", new Random().nextInt(10000));
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
        if (!StringUtils.hasText(username)) throw new IllegalArgumentException("Username is required.");
        if (!StringUtils.hasText(email)) throw new IllegalArgumentException("Email is required.");
        if (!StringUtils.hasText(password)) throw new IllegalArgumentException("Password is required.");
        if (!email.matches("^[\\w-.]+@([\\w-]+\\.)+[\\w-]{2,4}$")) throw new IllegalArgumentException("Invalid email format.");
    }

    public static class UsernameAlreadyExistsException extends RuntimeException {
        public UsernameAlreadyExistsException(String message) { super(message); }
    }
    public static class EmailAlreadyExistsException extends RuntimeException {
        public EmailAlreadyExistsException(String message) { super(message); }
    }
    public static class VerificationCodeException extends RuntimeException {
        public VerificationCodeException(String message) { super(message); }
    }
}