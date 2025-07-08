package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.MenuItemDTO;
import com.SmartCanteen.Backend.Entities.TodaysMenuItem;
import com.SmartCanteen.Backend.Services.MenuItemService;
import com.SmartCanteen.Backend.Services.TodaysMenuService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/menu/today")
@RequiredArgsConstructor
public class TodaysMenuController {

    private final TodaysMenuService todaysMenuService;
    private final MenuItemService menuItemService;

    @PostMapping
    public ResponseEntity<List<MenuItemDTO>> updateTodaysMenu(@RequestBody MenuSelectionRequest request) {
        List<MenuItemDTO> updatedMenu = todaysMenuService.updateTodaysMenu(request.getFoodIds());
        return ResponseEntity.ok(updatedMenu);
    }

    @GetMapping
    public ResponseEntity<List<MenuItemDTO>> getTodaysMenu() {
        List<MenuItemDTO> items = todaysMenuService.getTodaysMenu();
        return ResponseEntity.ok(items);
    }

    @Data
    public static class MenuSelectionRequest {
        private List<Long> foodIds;
    }
}
