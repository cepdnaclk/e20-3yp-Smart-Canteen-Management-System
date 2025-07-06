package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.FoodCategoryDTO;
import com.SmartCanteen.Backend.Services.FoodCategoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/food-categories")
@RequiredArgsConstructor
public class FoodCategoryController {

    private final FoodCategoryService foodCategoryService;

    @PostMapping
    public ResponseEntity<FoodCategoryDTO> createCategory(@Valid @RequestBody FoodCategoryDTO dto) {
        FoodCategoryDTO created = foodCategoryService.addCategory(dto);
        return ResponseEntity.ok(created);
    }

    @GetMapping
    public ResponseEntity<List<FoodCategoryDTO>> getAllCategories() {
        List<FoodCategoryDTO> categories = foodCategoryService.getAllCategories();
        return ResponseEntity.ok(categories);
    }

    @GetMapping("/with-items")
    public ResponseEntity<List<FoodCategoryDTO>> getAllCategoriesWithItems() {
        List<FoodCategoryDTO> categories = foodCategoryService.getAllCategoriesWithItems();
        return ResponseEntity.ok(categories);
    }

    @GetMapping("/{id}")
    public ResponseEntity<FoodCategoryDTO> getCategoryById(@PathVariable Long id) {
        FoodCategoryDTO category = foodCategoryService.getCategoryById(id);
        return ResponseEntity.ok(category);
    }

    @PutMapping("/{id}")
    public ResponseEntity<FoodCategoryDTO> updateCategory(@PathVariable Long id, @Valid @RequestBody FoodCategoryDTO dto) {
        FoodCategoryDTO updated = foodCategoryService.updateCategory(id, dto);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCategory(@PathVariable Long id) {
        boolean deleted = foodCategoryService.deleteCategory(id);
        if (!deleted) {
            return ResponseEntity.notFound().build();  // Return 404 if not found
        }
        return ResponseEntity.noContent().build();  // 204 No Content on success
    }

    // In FoodCategoryController.java

    @GetMapping("/with-today-menu")
    public ResponseEntity<List<FoodCategoryDTO>> getAllCategoriesWithTodayMenu() {
        // Implement this in your service to return categories with isInTodayMenu flags
        List<FoodCategoryDTO> categories = foodCategoryService.getAllCategoriesWithTodayMenu();
        return ResponseEntity.ok(categories);
    }

}
