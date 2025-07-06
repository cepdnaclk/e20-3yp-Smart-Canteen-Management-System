package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.MenuItemDTO;
import com.SmartCanteen.Backend.Entities.MenuItem;
import com.SmartCanteen.Backend.Entities.TodaysMenuItem;
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
public class TodaysMenuService {

    private final TodaysMenuRepository todaysMenuRepository;
    private final MenuItemRepository menuItemRepository;
    private final MenuItemService menuItemService;

    public List<MenuItemDTO> updateTodaysMenu(List<Long> foodIds) {
        LocalDate today = LocalDate.now();
        // Clear existing entries
        todaysMenuRepository.deleteByDate(today);

        // Create new entries
        List<TodaysMenuItem> newItems = foodIds.stream()
                .map(id -> {
                    MenuItem item = menuItemRepository.findById(id)
                            .orElseThrow(() -> new RuntimeException("MenuItem not found: " + id));
                    TodaysMenuItem tmItem = new TodaysMenuItem();
                    tmItem.setMenuItem(item);
                    tmItem.setDate(today);
                    return tmItem;
                })
                .toList();

        // Save all new items
        todaysMenuRepository.saveAll(newItems);

        // Return the updated today's menu as DTOs
        return menuItemService.getAllMenuItems().stream()
                .peek(dto -> dto.setIsInTodayMenu(foodIds.contains(dto.getId())))
                .toList();
    }

    public List<MenuItemDTO> getTodaysMenu() {
        List<Long> todayItemIds = todaysMenuRepository.findByDate(LocalDate.now()).stream()
                .map(tmi -> tmi.getMenuItem().getId())
                .toList();

        return menuItemService.getAllMenuItems().stream()
                .peek(dto -> dto.setIsInTodayMenu(todayItemIds.contains(dto.getId())))
                .collect(Collectors.toList());
    }
}
