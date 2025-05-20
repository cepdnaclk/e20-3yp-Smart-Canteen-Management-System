package com.SmartCanteen.Backend.EntityTests;

import com.SmartCanteen.Backend.DTOs.CustomerRequestDTO;
import com.SmartCanteen.Backend.DTOs.CustomerUpdateDTO;
import com.SmartCanteen.Backend.DTOs.LoginRequestDTO;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class CustomerCrudTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private CustomerRequestDTO customerRequest;
    private LoginRequestDTO loginRequest;
    private String authToken;

    @BeforeEach
    public void setup() {
        String uniqueUsername = "testuser_" + System.currentTimeMillis();

        customerRequest = new CustomerRequestDTO();
        customerRequest.setUsername(uniqueUsername);
        customerRequest.setEmail(uniqueUsername + "@example.com");
        customerRequest.setFullName("Test User");
        customerRequest.setPassword("password123");
        customerRequest.setCardID("CARD123");
        customerRequest.setFingerprintID("FINGERPRINT123");
        customerRequest.setCreditBalance(100.0);

        loginRequest = new LoginRequestDTO();
        loginRequest.setUsername(uniqueUsername);
        loginRequest.setPassword("password123");
    }

    @Test
    public void customerCrudFlow() throws Exception {
        // Register customer
        mockMvc.perform(post("/api/auth/register/customer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(customerRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value(customerRequest.getUsername()))
                .andExpect(jsonPath("$.email").value(customerRequest.getEmail()));

        // Login customer and extract token
        String loginResponse = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andReturn()
                .getResponse()
                .getContentAsString();

        authToken = objectMapper.readTree(loginResponse).get("token").asText();

        // Update profile
        CustomerUpdateDTO updateDTO = new CustomerUpdateDTO();
        updateDTO.setEmail("updated_" + customerRequest.getEmail());
        updateDTO.setFullName("Updated User");
        updateDTO.setCardID("NEWCARD123");
        updateDTO.setFingerprintID("NEWFINGERPRINT123");

        mockMvc.perform(put("/api/customer/profile")
                        .header("Authorization", "Bearer " + authToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(updateDTO.getEmail()))
                .andExpect(jsonPath("$.fullName").value(updateDTO.getFullName()));

        // Get profile and verify update
        mockMvc.perform(get("/api/customer/profile")
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(updateDTO.getEmail()))
                .andExpect(jsonPath("$.fullName").value(updateDTO.getFullName()));

        // Delete profile
        mockMvc.perform(delete("/api/customer/profile")
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk());

        // Verify login fails after deletion
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isUnauthorized());
    }
}
