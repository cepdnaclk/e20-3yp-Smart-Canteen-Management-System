package com.SmartCanteen.Backend.EntityTests;

import com.SmartCanteen.Backend.DTOs.AdminRequestDTO;
import com.SmartCanteen.Backend.DTOs.AdminUpdateDTO;
import com.SmartCanteen.Backend.DTOs.LoginRequestDTO;
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
public class AdminCrudTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private AdminRequestDTO adminRequest;
    private LoginRequestDTO loginRequest;
    private String authToken;

    @BeforeEach
    public void setup() {
        String uniqueUsername = "adminuser_" + System.currentTimeMillis();

        adminRequest = new AdminRequestDTO();
        adminRequest.setUsername(uniqueUsername);
        adminRequest.setEmail(uniqueUsername + "@example.com");
        adminRequest.setFullName("Admin User");
        adminRequest.setPassword("adminPass123");
        adminRequest.setCardID("ADMINCARD123");
        adminRequest.setFingerprintID("ADMINFINGERPRINT123");
        adminRequest.setCreditBalance(0.0); // if applicable

        loginRequest = new LoginRequestDTO();
        loginRequest.setUsername(uniqueUsername);
        loginRequest.setPassword("adminPass123");
    }

    @Test
    public void adminCrudFlow() throws Exception {
        // Register admin
        mockMvc.perform(post("/api/auth/register/admin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(adminRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value(adminRequest.getUsername()))
                .andExpect(jsonPath("$.email").value(adminRequest.getEmail()));

        // Login admin and extract token
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
        AdminUpdateDTO updateDTO = new AdminUpdateDTO();
        updateDTO.setEmail("updated_" + adminRequest.getEmail());
        updateDTO.setFullName("Updated Admin");
        updateDTO.setCardID("NEWADMINCARD123");
        updateDTO.setFingerprintID("NEWADMINFINGERPRINT123");

        mockMvc.perform(put("/api/admin/profile")
                        .header("Authorization", "Bearer " + authToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(updateDTO.getEmail()))
                .andExpect(jsonPath("$.fullName").value(updateDTO.getFullName()));

        // Get profile and verify update
        mockMvc.perform(get("/api/admin/profile")
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(updateDTO.getEmail()))
                .andExpect(jsonPath("$.fullName").value(updateDTO.getFullName()));

        // Delete profile
        mockMvc.perform(delete("/api/admin/profile")
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk());

        // Verify login fails after deletion
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isUnauthorized());
    }
}
