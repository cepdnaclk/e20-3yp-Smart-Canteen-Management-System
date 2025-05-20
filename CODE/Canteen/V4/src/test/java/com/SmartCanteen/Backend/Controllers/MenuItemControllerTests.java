package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.FoodCategoryDTO;
import com.SmartCanteen.Backend.DTOs.MenuItemDTO;
import com.SmartCanteen.Backend.Repositories.FoodCategoryRepository;
import com.SmartCanteen.Backend.Repositories.MenuItemRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class MenuItemControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private FoodCategoryRepository foodCategoryRepository;

    @Autowired
    private MenuItemRepository menuItemRepository;

    private FoodCategoryDTO categoryDTO;
    private Long categoryId;

    private MenuItemDTO menuItemDTO;

    @BeforeEach
    public void setup() throws Exception {
        // Clean DB to avoid conflicts
        menuItemRepository.deleteAll();
        foodCategoryRepository.deleteAll();

        // Create a FoodCategory first as MenuItem requires it
        categoryDTO = new FoodCategoryDTO();
        categoryDTO.setName("Test Category");
        categoryDTO.setDescription("Description for test category");

        String categoryResponse = mockMvc.perform(post("/api/food-categories")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(categoryDTO)))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        FoodCategoryDTO createdCategory = objectMapper.readValue(categoryResponse, FoodCategoryDTO.class);
        categoryId = createdCategory.getId();

        // Prepare MenuItemDTO with the created categoryId
        menuItemDTO = new MenuItemDTO();
        menuItemDTO.setName("Test Menu Item");
        menuItemDTO.setCategoryId(categoryId);
        menuItemDTO.setPrice(BigDecimal.valueOf(9.99));
        menuItemDTO.setStock(100);
    }

    @Test
    public void testCreateReadUpdateDeleteMenuItem() throws Exception {
        // Create MenuItem
        String createResponse = mockMvc.perform(post("/api/menu-items")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(menuItemDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value(menuItemDTO.getName()))
                .andExpect(jsonPath("$.categoryId").value(categoryId))
                .andReturn()
                .getResponse()
                .getContentAsString();

        MenuItemDTO createdItem = objectMapper.readValue(createResponse, MenuItemDTO.class);
        Long menuItemId = createdItem.getId();

        // Read MenuItem by ID
        mockMvc.perform(get("/api/menu-items/{id}", menuItemId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(menuItemId))
                .andExpect(jsonPath("$.name").value(menuItemDTO.getName()));

        // Update MenuItem
        createdItem.setName("Updated Menu Item");
        createdItem.setPrice(BigDecimal.valueOf(12.99));
        createdItem.setStock(50);

        mockMvc.perform(put("/api/menu-items/{id}", menuItemId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createdItem)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Updated Menu Item"))
                .andExpect(jsonPath("$.price").value(12.99))
                .andExpect(jsonPath("$.stock").value(50));

        // Delete MenuItem
        mockMvc.perform(delete("/api/menu-items/{id}", menuItemId))
                .andExpect(status().isNoContent());

        // Verify deletion returns 404 Not Found
        mockMvc.perform(get("/api/menu-items/{id}", menuItemId))
                .andExpect(status().isNotFound());
    }
}
