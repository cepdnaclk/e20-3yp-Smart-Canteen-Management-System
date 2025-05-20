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

    @GetMapping
    public ResponseEntity<List<FoodCategoryDTO>> getAllCategories() {
        return ResponseEntity.ok(categoryService.getAllCategories());
    }

    @PostMapping
    public ResponseEntity<FoodCategoryDTO> addCategory(@RequestBody FoodCategoryDTO dto) {
        return ResponseEntity.ok(categoryService.addCategory(dto));
    }
}
