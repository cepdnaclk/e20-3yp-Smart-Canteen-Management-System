package com.SmartCanteen.Backend.DTOs;

import lombok.Data;

import java.util.List;

@Data
public class FoodCategoryDTO {
    private Long id;
    private String name;
    private String description;
    private List<MenuItemDTO> menuItems;  // For hierarchical response
}
