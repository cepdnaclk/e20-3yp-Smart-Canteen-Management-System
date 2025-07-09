package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.FoodCategoryDTO;
import com.SmartCanteen.Backend.Services.FoodCategoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/foodcategories")
@RequiredArgsConstructor
public class FoodCategoryController {

    private final FoodCategoryService foodCategoryService;

    @GetMapping
    public ResponseEntity<List<FoodCategoryDTO>> getAllCategories() {
        return ResponseEntity.ok(foodCategoryService.getAllCategories());
    }

    @PostMapping
    public ResponseEntity<FoodCategoryDTO> addCategory(@RequestBody FoodCategoryDTO dto) {
        return ResponseEntity.ok(foodCategoryService.addCategory(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<FoodCategoryDTO> updateCategory(@PathVariable Long id, @RequestBody FoodCategoryDTO dto) {
        return ResponseEntity.ok(foodCategoryService.updateCategory(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteCategory(@PathVariable Long id) {
        foodCategoryService.deleteCategory(id);
        return ResponseEntity.ok("Category deleted successfully");
    }
}
