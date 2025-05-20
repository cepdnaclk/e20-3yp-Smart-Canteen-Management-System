package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.FoodCategoryDTO;
import com.SmartCanteen.Backend.Repositories.FoodCategoryRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class FoodCategoryControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private FoodCategoryRepository foodCategoryRepository;

    private FoodCategoryDTO categoryDTO;  // Declare here

    @BeforeEach
    public void setup() {
        // Clean database before each test to avoid duplicates
        foodCategoryRepository.deleteAll();

        // Initialize DTO for testing
        categoryDTO = new FoodCategoryDTO();
        categoryDTO.setName("Test Category");
        categoryDTO.setDescription("Description for test category");
    }

    @Test
    public void testCreateReadUpdateDeleteCategory() throws Exception {
        // Create category
        String createResponse = mockMvc.perform(post("/api/food-categories")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(categoryDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value(categoryDTO.getName()))
                .andReturn()
                .getResponse()
                .getContentAsString();

        FoodCategoryDTO createdCategory = objectMapper.readValue(createResponse, FoodCategoryDTO.class);
        Long categoryId = createdCategory.getId();

        // Read category by ID
        mockMvc.perform(get("/api/food-categories/{id}", categoryId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(categoryId))
                .andExpect(jsonPath("$.name").value(categoryDTO.getName()));

        // Update category
        createdCategory.setName("Updated Category Name");
        createdCategory.setDescription("Updated description");

        mockMvc.perform(put("/api/food-categories/{id}", categoryId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createdCategory)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Updated Category Name"))
                .andExpect(jsonPath("$.description").value("Updated description"));

        // Delete category
        mockMvc.perform(delete("/api/food-categories/{id}", categoryId))
                .andExpect(status().isNoContent());

        // Verify deletion returns 404 Not Found
        mockMvc.perform(get("/api/food-categories/{id}", categoryId))
                .andExpect(status().isNotFound());
    }
}
