package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.MenuItemDTO;
import com.SmartCanteen.Backend.Entities.FoodCategory;
import com.SmartCanteen.Backend.Entities.MenuItem;
import com.SmartCanteen.Backend.Repositories.FoodCategoryRepository;
import com.SmartCanteen.Backend.Repositories.MenuItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MenuItemService {

    private final MenuItemRepository menuItemRepository;
    private final FoodCategoryRepository foodCategoryRepository;

    // Create
    public MenuItemDTO addMenuItem(MenuItemDTO dto) {
        FoodCategory category = foodCategoryRepository.findById(dto.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Category not found"));
        MenuItem item = new MenuItem();
        item.setName(dto.getName());
        item.setPrice(dto.getPrice());
        item.setStock(dto.getStock());
        item.setCategory(category);
        MenuItem saved = menuItemRepository.save(item);
        return mapToDTO(saved);
    }

    // Read all
    public List<MenuItemDTO> getAllMenuItems() {
        return menuItemRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    // Read by category
    public List<MenuItemDTO> getItemsByCategory(Long categoryId) {
        return menuItemRepository.findByCategoryId(categoryId).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    // Read one
    public MenuItemDTO getMenuItemById(Long id) {
        MenuItem item = menuItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Menu item not found with id: " + id));
        return mapToDTO(item);
    }

    // Update
    public MenuItemDTO updateMenuItem(Long id, MenuItemDTO dto) {
        MenuItem item = menuItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Menu item not found with id: " + id));
        FoodCategory category = foodCategoryRepository.findById(dto.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Category not found"));
        item.setName(dto.getName());
        item.setPrice(dto.getPrice());
        item.setStock(dto.getStock());
        item.setCategory(category);
        MenuItem updated = menuItemRepository.save(item);
        return mapToDTO(updated);
    }

    // Delete
    public void deleteMenuItem(Long id) {
        if (!menuItemRepository.existsById(id)) {
            throw new RuntimeException("Menu item not found with id: " + id);
        }
        menuItemRepository.deleteById(id);
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
