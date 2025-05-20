package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.FoodCategoryDTO;
import com.SmartCanteen.Backend.DTOs.MenuItemDTO;
import com.SmartCanteen.Backend.Entities.FoodCategory;
import com.SmartCanteen.Backend.Entities.MenuItem;
import com.SmartCanteen.Backend.Exceptions.GlobalExceptionHandler;
import com.SmartCanteen.Backend.Exceptions.ResourceNotFoundException;
import com.SmartCanteen.Backend.Repositories.FoodCategoryRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class FoodCategoryService {

    private final FoodCategoryRepository foodCategoryRepository;

    // Create
    public FoodCategoryDTO addCategory(FoodCategoryDTO dto) {
        if (foodCategoryRepository.existsByName(dto.getName())) {
            throw new GlobalExceptionHandler.DuplicateResourceException("Category with name '" + dto.getName() + "' already exists.");
        }
        FoodCategory category = new FoodCategory();
        category.setName(dto.getName());
        category.setDescription(dto.getDescription());
        FoodCategory saved = foodCategoryRepository.save(category);
        return mapToDTO(saved);
    }



    // Read all (without items)
    public List<FoodCategoryDTO> getAllCategories() {
        List<FoodCategory> categories = foodCategoryRepository.findAll();
        return categories.stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    // Read all with items
    public List<FoodCategoryDTO> getAllCategoriesWithItems() {
        List<FoodCategory> categories = foodCategoryRepository.findAll();
        return categories.stream()
                .map(this::mapToDTOWithItems)
                .collect(Collectors.toList());
    }

    // Read one with items
    public FoodCategoryDTO getCategoryById(Long id) {
        FoodCategory category = foodCategoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with id: " + id));
        return mapToDTOWithItems(category);
    }

    // Update
    public FoodCategoryDTO updateCategory(Long id, FoodCategoryDTO dto) {
        FoodCategory category = foodCategoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with id: " + id));
        category.setName(dto.getName());
        category.setDescription(dto.getDescription());
        FoodCategory updated = foodCategoryRepository.save(category);
        return mapToDTO(updated);
    }

    // Delete
    public boolean deleteCategory(Long id) {
        if (!foodCategoryRepository.existsById(id)) {
            return false;  // Indicate category not found
        }
        foodCategoryRepository.deleteById(id);
        return true;  // Indicate successful deletion
    }

    // Mapping helpers

    private FoodCategoryDTO mapToDTOWithItems(FoodCategory category) {
        FoodCategoryDTO dto = new FoodCategoryDTO();
        dto.setId(category.getId());
        dto.setName(category.getName());
        dto.setDescription(category.getDescription());

        List<MenuItemDTO> items = category.getMenuItems() == null ? List.of() :
                category.getMenuItems().stream()
                        .map(this::mapMenuItemToDTO)
                        .collect(Collectors.toList());

        dto.setMenuItems(items);
        return dto;
    }

    private FoodCategoryDTO mapToDTO(FoodCategory category) {
        FoodCategoryDTO dto = new FoodCategoryDTO();
        dto.setId(category.getId());
        dto.setName(category.getName());
        dto.setDescription(category.getDescription());
        return dto;
    }

    private MenuItemDTO mapMenuItemToDTO(MenuItem item) {
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
