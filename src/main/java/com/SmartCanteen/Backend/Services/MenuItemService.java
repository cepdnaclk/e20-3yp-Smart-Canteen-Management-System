package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.MenuItemDTO;
import com.SmartCanteen.Backend.Entities.FoodCategory;
import com.SmartCanteen.Backend.Entities.MenuItem;
import com.SmartCanteen.Backend.Exceptions.ResourceNotFoundException;
import com.SmartCanteen.Backend.Repositories.FoodCategoryRepository;
import com.SmartCanteen.Backend.Repositories.MenuItemRepository;
import com.SmartCanteen.Backend.Repositories.TodaysMenuRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class MenuItemService {

    private final MenuItemRepository menuItemRepository;
    private final FoodCategoryRepository foodCategoryRepository;
    private final TodaysMenuRepository todaysMenuRepository;

    public MenuItemDTO addMenuItem(MenuItemDTO dto) {
        FoodCategory category = foodCategoryRepository.findById(dto.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with id: " + dto.getCategoryId()));

        MenuItem item = new MenuItem();
        item.setName(dto.getName());
        item.setPrice(dto.getPrice());
        item.setStock(dto.getStock());
        item.setCategory(category);
        item.setImagePath(dto.getImagePath());

        MenuItem saved = menuItemRepository.save(item);

        boolean isInToday = todaysMenuRepository.existsByMenuItemIdAndDate(saved.getId(), LocalDate.now());
        return mapToDTO(saved, isInToday);

    }

    public List<MenuItemDTO> getAllMenuItems() {
        List<Long> todayItemIds = todaysMenuRepository.findByDate(LocalDate.now()).stream()
                .map(tmi -> tmi.getMenuItem().getId())
                .collect(Collectors.toList());

        return menuItemRepository.findAll().stream()
                .map(item -> mapToDTO(item, todayItemIds.contains(item.getId())))
                .collect(Collectors.toList());
    }

    public List<MenuItemDTO> getItemsByCategory(Long categoryId) {
        List<Long> todayItemIds = todaysMenuRepository.findByDate(LocalDate.now()).stream()
                .map(tmi -> tmi.getMenuItem().getId())
                .collect(Collectors.toList());

        return menuItemRepository.findByCategoryId(categoryId).stream()
                .map(item -> mapToDTO(item, todayItemIds.contains(item.getId())))
                .collect(Collectors.toList());
    }

    public MenuItemDTO getMenuItemById(Long id) {
        MenuItem item = menuItemRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Menu item not found with id: " + id));
        boolean isInToday = todaysMenuRepository.existsByMenuItemIdAndDate(id, LocalDate.now());
        return mapToDTO(item, isInToday);
    }

    public MenuItemDTO updateMenuItem(Long id, MenuItemDTO dto) {
        MenuItem item = menuItemRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Menu item not found with id: " + id));

        FoodCategory category = foodCategoryRepository.findById(dto.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with id: " + dto.getCategoryId()));

        item.setName(dto.getName());
        item.setPrice(dto.getPrice());
        item.setStock(dto.getStock());
        item.setCategory(category);

        MenuItem updated = menuItemRepository.save(item);
        boolean isInToday = todaysMenuRepository.existsByMenuItemIdAndDate(id, LocalDate.now());
        return mapToDTO(updated, isInToday);
    }

    public boolean deleteMenuItem(Long id) {
        if (!menuItemRepository.existsById(id)) {
            return false;
        }
        menuItemRepository.deleteById(id);
        return true;
    }

    private MenuItemDTO mapToDTO(MenuItem item, boolean isInTodayMenu) {
        MenuItemDTO dto = new MenuItemDTO();
        dto.setId(item.getId());
        dto.setName(item.getName());
        dto.setCategoryId(item.getCategory().getId());
        dto.setCategoryName(item.getCategory().getName());
        dto.setPrice(item.getPrice());
        dto.setStock(item.getStock());
        dto.setImagePath(item.getImagePath());
        dto.setIsInTodayMenu(isInTodayMenu);
        return dto;
    }
}
