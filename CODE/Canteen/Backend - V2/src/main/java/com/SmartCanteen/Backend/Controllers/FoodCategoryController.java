package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.FoodCategoryDTO;
import com.SmartCanteen.Backend.Services.FoodCategoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
public class FoodCategoryController {

    private final FoodCategoryService categoryService;

    @PostMapping
    public ResponseEntity<FoodCategoryDTO> addCategory(@RequestBody FoodCategoryDTO dto) {
        return ResponseEntity.ok(categoryService.addCategory(dto));
    }

    @GetMapping
    public ResponseEntity<List<FoodCategoryDTO>> getAllCategories() {
        return ResponseEntity.ok(categoryService.getAllCategories());
    }

    @GetMapping("/{id}")
    public ResponseEntity<FoodCategoryDTO> getCategoryById(@PathVariable Long id) {
        return ResponseEntity.ok(categoryService.getCategoryById(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<FoodCategoryDTO> updateCategory(@PathVariable Long id, @RequestBody FoodCategoryDTO dto) {
        return ResponseEntity.ok(categoryService.updateCategory(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCategory(@PathVariable Long id) {
        categoryService.deleteCategory(id);
        return ResponseEntity.noContent().build();
    }

    // Optional: get categories with their menu items
    @GetMapping("/with-items")
    public ResponseEntity<List<FoodCategoryDTO>> getCategoriesWithMenuItems() {
        return ResponseEntity.ok(categoryService.getAllCategoriesWithItems());
    }
}
