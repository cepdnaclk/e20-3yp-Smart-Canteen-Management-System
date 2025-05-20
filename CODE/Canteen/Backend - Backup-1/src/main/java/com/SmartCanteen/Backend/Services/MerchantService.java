package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.MenuItemDTO;
import com.SmartCanteen.Backend.DTOs.MerchantResponseDTO;
import com.SmartCanteen.Backend.Entities.MenuItem;
import com.SmartCanteen.Backend.Entities.Merchant;
import com.SmartCanteen.Backend.Entities.Customer;
import com.SmartCanteen.Backend.Entities.FoodCategory;
import com.SmartCanteen.Backend.Repositories.CustomerRepository;
import com.SmartCanteen.Backend.Repositories.MenuItemRepository;
import com.SmartCanteen.Backend.Repositories.MerchantRepository;
import com.SmartCanteen.Backend.Repositories.FoodCategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MerchantService {

    private final MerchantRepository merchantRepository;
    private final MenuItemRepository menuItemRepository;
    private final CustomerRepository customerRepository;
    private final NotificationService notificationService;
    private final FoodCategoryRepository foodCategoryRepository; // <-- Add this

    public MerchantResponseDTO getProfile() {
        Merchant merchant = getCurrentMerchant();
        MerchantResponseDTO dto = new MerchantResponseDTO();
        dto.setId(merchant.getId());
        dto.setUsername(merchant.getUsername());
        dto.setEmail(merchant.getEmail());
        dto.setFullName(merchant.getFullName());
        return dto;
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

    // Helper to get current logged-in merchant
    private Merchant getCurrentMerchant() {
        // Implement retrieval from security context
        throw new UnsupportedOperationException("Implement security context user retrieval");
    }

    private MenuItemDTO mapToDTO(MenuItem item) {
        MenuItemDTO dto = new MenuItemDTO();
        dto.setId(item.getId());
        dto.setName(item.getName());
        dto.setCategoryId(item.getCategory().getId());
        dto.setCategoryName(item.getCategory().getName());
        dto.setPrice(item.getPrice());
        dto.setStock(item.getStock());
        return dto;
    }
}
