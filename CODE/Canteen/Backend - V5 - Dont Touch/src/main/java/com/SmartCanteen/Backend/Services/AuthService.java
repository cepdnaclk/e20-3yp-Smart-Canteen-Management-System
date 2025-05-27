package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.*;
import com.SmartCanteen.Backend.Entities.*;
import com.SmartCanteen.Backend.Repositories.*;
import com.SmartCanteen.Backend.Security.JwtTokenProvider;
import com.SmartCanteen.Backend.Security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final AdminRepository adminRepository;
    private final CustomerRepository customerRepository;
    private final MerchantRepository merchantRepository;

    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final AuthenticationManager authenticationManager;

    public AuthResponseDTO authenticateUser(LoginRequestDTO loginRequest) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(loginRequest.getUsername(), loginRequest.getPassword())
            );
        } catch (AuthenticationException ex) {
            throw new BadCredentialsException("Invalid username or password");
        }

        User user = userRepository.findByUsername(loginRequest.getUsername())
                .orElseThrow(() -> new BadCredentialsException("User not found"));

        String token = jwtTokenProvider.generateToken(user.getUsername(), user.getRole().name());

        AuthResponseDTO response = new AuthResponseDTO();
        response.setToken(token);
        response.setUserId(user.getId());
        response.setUsername(user.getUsername());
        response.setRole(user.getRole().name());
        return response;
    }

    public CustomerResponseDTO registerCustomer(CustomerRequestDTO dto) {
        if (userRepository.existsByUsername(dto.getUsername())) {
            throw new UsernameAlreadyExistsException("Username is already taken");
        }


        Customer customer = new Customer();
        customer.setUsername(dto.getUsername());
        customer.setEmail(dto.getEmail());
        customer.setFullName(dto.getFullName());
        customer.setPassword(passwordEncoder.encode(dto.getPassword()));
        customer.setCardID(dto.getCardID());
        customer.setFingerprintID(dto.getFingerprintID());
        customer.setCreditBalance(dto.getCreditBalance() != null ? BigDecimal.valueOf(dto.getCreditBalance()) : BigDecimal.ZERO);
        customer.setRole(Role.CUSTOMER);

        customerRepository.save(customer);

        CustomerResponseDTO response = new CustomerResponseDTO();
        response.setId(customer.getId());
        response.setUsername(customer.getUsername());
        response.setEmail(customer.getEmail());
        response.setFullName(customer.getFullName());
        response.setCreditBalance(customer.getCreditBalance());
        return response;
    }

    public MerchantResponseDTO registerMerchant(MerchantRequestDTO dto) {
        if (userRepository.existsByUsername(dto.getUsername())) {
            throw new UsernameAlreadyExistsException("Username is already taken");
        }

        Merchant merchant = new Merchant();
        merchant.setUsername(dto.getUsername());
        merchant.setEmail(dto.getEmail());
        merchant.setFullName(dto.getFullName());
        merchant.setPassword(passwordEncoder.encode(dto.getPassword()));
        merchant.setCardID(dto.getCardID());
        merchant.setFingerprintID(dto.getFingerprintID());
        merchant.setRole(Role.MERCHANT);

        merchantRepository.save(merchant);

        MerchantResponseDTO response = new MerchantResponseDTO();
        response.setId(merchant.getId());
        response.setUsername(merchant.getUsername());
        response.setEmail(merchant.getEmail());
        response.setFullName(merchant.getFullName());
        return response;
    }

    public AdminResponseDTO registerAdmin(AdminRequestDTO dto) {
        if (userRepository.existsByUsername(dto.getUsername())) {
            throw new UsernameAlreadyExistsException("Username is already taken");
        }

        Admin admin = new Admin();
        admin.setUsername(dto.getUsername());
        admin.setEmail(dto.getEmail());
        admin.setFullName(dto.getFullName());
        admin.setPassword(passwordEncoder.encode(dto.getPassword()));
        admin.setCardID(dto.getCardID());
        admin.setFingerprintID(dto.getFingerprintID());
        admin.setRole(Role.ADMIN);

        adminRepository.save(admin);

        AdminResponseDTO response = new AdminResponseDTO();
        response.setId(admin.getId());
        response.setUsername(admin.getUsername());
        response.setEmail(admin.getEmail());
        response.setFullName(admin.getFullName());
        return response;
    }

    // Custom exception class for duplicate username
    public static class UsernameAlreadyExistsException extends RuntimeException {
        public UsernameAlreadyExistsException(String message) {
            super(message);
        }
    }

    public Long getUserIdFromUserDetails(UserDetails userDetails) {
        if (userDetails instanceof UserPrincipal) {
            return ((UserPrincipal) userDetails).getId();
        }
        throw new RuntimeException("User ID not found in UserDetails");
    }

}
