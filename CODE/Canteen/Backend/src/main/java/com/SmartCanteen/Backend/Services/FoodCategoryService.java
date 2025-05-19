package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.FoodCategoryDTO;
import com.SmartCanteen.Backend.Entities.FoodCategory;
import com.SmartCanteen.Backend.Repositories.FoodCategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FoodCategoryService {

    private final FoodCategoryRepository foodCategoryRepository;

    public List<FoodCategoryDTO> getAllCategories() {
        return foodCategoryRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public FoodCategoryDTO addCategory(FoodCategoryDTO dto) {
        FoodCategory category = new FoodCategory();
        category.setName(dto.getName());
        category.setDescription(dto.getDescription());
        FoodCategory saved = foodCategoryRepository.save(category);
        return mapToDTO(saved);
    }

    public FoodCategoryDTO updateCategory(Long id, FoodCategoryDTO dto) {
        FoodCategory category = foodCategoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found"));
        category.setName(dto.getName());
        category.setDescription(dto.getDescription());
        FoodCategory updated = foodCategoryRepository.save(category);
        return mapToDTO(updated);
    }

    public void deleteCategory(Long id) {
        foodCategoryRepository.deleteById(id);
    }

    private FoodCategoryDTO mapToDTO(FoodCategory category) {
        FoodCategoryDTO dto = new FoodCategoryDTO();
        dto.setId(category.getId());
        dto.setName(category.getName());
        dto.setDescription(category.getDescription());
        return dto;
    }
}
