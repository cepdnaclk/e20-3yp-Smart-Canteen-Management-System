package com.SmartCanteen.Backend.Services;

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
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
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
    private final FoodCategoryRepository foodCategoryRepository;
    private final ModelMapper modelMapper;

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
        dto.setStock(item.getStock());
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


}
