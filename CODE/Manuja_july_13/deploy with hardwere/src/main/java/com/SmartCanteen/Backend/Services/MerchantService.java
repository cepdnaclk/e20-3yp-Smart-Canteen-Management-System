package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.CustomerBiometricUpdateDTO;
import com.SmartCanteen.Backend.DTOs.MenuItemDTO;
import com.SmartCanteen.Backend.DTOs.MerchantResponseDTO;
import com.SmartCanteen.Backend.DTOs.MerchantUpdateDTO;
import com.SmartCanteen.Backend.Entities.Customer;
import com.SmartCanteen.Backend.Entities.FoodCategory;
import com.SmartCanteen.Backend.Entities.MenuItem;
import com.SmartCanteen.Backend.Entities.Merchant;
import com.SmartCanteen.Backend.Repositories.CustomerRepository;
import com.SmartCanteen.Backend.Repositories.FoodCategoryRepository;
import com.SmartCanteen.Backend.Repositories.MenuItemRepository;
import com.SmartCanteen.Backend.Repositories.MerchantRepository;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
// Removed org.springframework.security.core.userdetails.UserDetails and org.springframework.security.oauth2.jwt.Jwt
// as they are no longer needed for token extraction in this service
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class MerchantService {

    private final MerchantRepository merchantRepository;
    private final MenuItemRepository menuItemRepository;
    private final CustomerRepository customerRepository;
    private final NotificationService notificationService;
    private final FoodCategoryRepository foodCategoryRepository;
    private final ModelMapper modelMapper;
    private final RestTemplate restTemplate;

    @Autowired
    public MerchantService(MerchantRepository merchantRepository,
                           MenuItemRepository menuItemRepository,
                           CustomerRepository customerRepository,
                           NotificationService notificationService,
                           FoodCategoryRepository foodCategoryRepository,
                           ModelMapper modelMapper,
                           RestTemplate restTemplate) {
        this.merchantRepository = merchantRepository;
        this.menuItemRepository = menuItemRepository;
        this.customerRepository = customerRepository;
        this.notificationService = notificationService;
        this.foodCategoryRepository = foodCategoryRepository;
        this.modelMapper = modelMapper;
        this.restTemplate = restTemplate;
    }


    public MerchantResponseDTO getProfile() {
        Merchant merchant = getCurrentAuthenticatedMerchant();
        return modelMapper.map(merchant, MerchantResponseDTO.class);
    }


    public void deleteCurrentMerchant() {
        Merchant merchant = getCurrentAuthenticatedMerchant();
        merchantRepository.delete(merchant);
    }

    public List<MenuItemDTO> getMenuItems() {
        return menuItemRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public void addMenuItem(MenuItemDTO dto) {
        MenuItem item = new MenuItem();
        item.setName(dto.getName());

        FoodCategory category = foodCategoryRepository.findById(dto.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Category not found"));
        item.setCategory(category);

        item.setPrice(dto.getPrice());
        item.setStock(dto.getStock());
        menuItemRepository.save(item);
    }

    public void updateMenuItem(Long id, MenuItemDTO dto) {
        MenuItem item = menuItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Menu item not found"));
        item.setName(dto.getName());

        FoodCategory category = foodCategoryRepository.findById(dto.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Category not found"));
        item.setCategory(category);

        item.setPrice(dto.getPrice());
        item.setStock(dto.getStock());
        menuItemRepository.save(item);
    }

    public void deleteMenuItem(Long id) {
        menuItemRepository.deleteById(id);
    }

    public void topUpCustomerCredit(Long customerId, double amount) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new RuntimeException("Customer not found"));
        customer.setCreditBalance(customer.getCreditBalance().add(java.math.BigDecimal.valueOf(amount)));
        customerRepository.save(customer);

        notificationService.sendNotification(customer, "Your credit balance has been topped up by " + amount);
    }

    private MenuItemDTO mapToDTO(MenuItem item) {
        MenuItemDTO dto = new MenuItemDTO();
        dto.setId(item.getId());
        dto.setName(item.getName());
        dto.setCategoryId(item.getCategory().getId());
        dto.setCategoryName(item.getCategory().getName());
        dto.setPrice(item.getPrice());
        dto.setStock(dto.getStock());
        return dto;
    }

    public Merchant getCurrentAuthenticatedMerchant() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || !authentication.isAuthenticated()) {
            throw new UsernameNotFoundException("No authenticated user found");
        }

        String username = authentication.getName();

        return merchantRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("Merchant not found with username: " + username));
    }

    public MerchantResponseDTO updateProfile(MerchantUpdateDTO updateDTO) {
        Merchant merchant = getCurrentAuthenticatedMerchant();
        merchant.setEmail(updateDTO.getEmail());
        merchant.setFullName(updateDTO.getCanteenName());
        merchant.setCardID(updateDTO.getCardID());
        merchant.setFingerprintID(updateDTO.getFingerprintID());
        merchantRepository.save(merchant);
        return modelMapper.map(merchant, MerchantResponseDTO.class);
    }

    //manuja
    private static final String RASPBERRY_PI_URL = "http://100.93.177.42:5000/api/merchant/request-biometrics";

    // ✨ Modified method signature to accept 'token' as a parameter
    public void updateCustomerBiometricsByEmail(CustomerBiometricUpdateDTO dto, String token) {
        String email = dto.getEmail();
        if (email == null || email.isEmpty()) {
            throw new IllegalArgumentException("Email is required");
        }

        // --- Removed JWT Token Extraction logic from here ---
        // It should now be handled by the caller (e.g., BiometricAuthController)
        if (token == null || token.isEmpty()) { // Validate the passed token
            System.err.println("JWT Token is null or empty. Cannot proceed with request to Raspberry Pi.");
            throw new RuntimeException("Authentication token not available to send to Raspberry Pi.");
        }
        // --- End of Removed JWT Token Extraction ---

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer " + token); // Use the passed token

            Map<String, String> body = new HashMap<>();
            body.put("email", email);

            HttpEntity<Map<String, String>> request = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = this.restTemplate.postForEntity(RASPBERRY_PI_URL, request, String.class);

            System.out.println("✅ Raspberry Pi Response: " + response.getStatusCode() + " - " + response.getBody());

        } catch (Exception e) {
            System.err.println("❌ Error contacting Raspberry Pi: " + e.getMessage());
            throw new RuntimeException("Failed to contact Raspberry Pi", e);
        }
    }
}