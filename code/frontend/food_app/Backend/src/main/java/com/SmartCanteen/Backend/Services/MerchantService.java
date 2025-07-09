package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.MenuItemDTO;
import com.SmartCanteen.Backend.DTOs.MerchantResponseDTO;
import com.SmartCanteen.Backend.Entities.MenuItem;
import com.SmartCanteen.Backend.Entities.Merchant;
import com.SmartCanteen.Backend.Entities.Customer;
import com.SmartCanteen.Backend.Repositories.CustomerRepository;
import com.SmartCanteen.Backend.Repositories.MenuItemRepository;
import com.SmartCanteen.Backend.Repositories.MerchantRepository;
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

    public MerchantResponseDTO getProfile() {
        Merchant merchant = getCurrentMerchant();
        MerchantResponseDTO dto = new MerchantResponseDTO();
        dto.setId(merchant.getId());
        dto.setUsername(merchant.getUsername());
        dto.setEmail(merchant.getEmail());
        dto.setCanteenName(merchant.getCanteenName());

//        dto.setFullName(merchant.getFullName());
        return dto;
    }

    public List<MenuItemDTO> getMenuItems() {
        return menuItemRepository.findAll().stream()
                .map(this::mapMenuItemToDTO)
                .collect(Collectors.toList());
    }

    public void addMenuItem(MenuItemDTO dto) {
        MenuItem item = new MenuItem();
        item.setName(dto.getName());
        item.setCategory(dto.getCategory());
        item.setPrice(dto.getPrice());
        item.setStock(dto.getStock());
        menuItemRepository.save(item);
    }

    public void updateMenuItem(Long id, MenuItemDTO dto) {
        MenuItem item = menuItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Menu item not found"));
        item.setName(dto.getName());
        item.setCategory(dto.getCategory());
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

    private MenuItemDTO mapMenuItemToDTO(MenuItem item) {
        MenuItemDTO dto = new MenuItemDTO();
        dto.setId(item.getId());
        dto.setName(item.getName());
        dto.setCategory(item.getCategory());
        dto.setPrice(item.getPrice());
        dto.setStock(item.getStock());
        return dto;
    }
}
