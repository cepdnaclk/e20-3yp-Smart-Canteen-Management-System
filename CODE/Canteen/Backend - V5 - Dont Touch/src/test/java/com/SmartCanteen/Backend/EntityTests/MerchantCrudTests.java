package com.SmartCanteen.Backend.EntityTests;


import com.SmartCanteen.Backend.DTOs.LoginRequestDTO;
import com.SmartCanteen.Backend.DTOs.MerchantRequestDTO;
import com.SmartCanteen.Backend.DTOs.MerchantUpdateDTO;
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
public class MerchantCrudTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private MerchantRequestDTO merchantRequest;
    private LoginRequestDTO loginRequest;
    private String authToken;

    @BeforeEach
    public void setup() {
        String uniqueUsername = "merchantuser_" + System.currentTimeMillis();

        merchantRequest = new MerchantRequestDTO();
        merchantRequest.setUsername(uniqueUsername);
        merchantRequest.setEmail(uniqueUsername + "@example.com");
        merchantRequest.setFullName("Merchant User");
        merchantRequest.setPassword("merchantPass123");
        merchantRequest.setCardID("MERCHANTCARD123");
        merchantRequest.setFingerprintID("MERCHANTFINGERPRINT123");
        merchantRequest.setCreditBalance(BigDecimal.valueOf(0.0)); // if applicable

        loginRequest = new LoginRequestDTO();
        loginRequest.setUsername(uniqueUsername);
        loginRequest.setPassword("merchantPass123");
    }

    @Test
    public void merchantCrudFlow() throws Exception {
        // Register merchant
        mockMvc.perform(post("/api/auth/register/merchant")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(merchantRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value(merchantRequest.getUsername()))
                .andExpect(jsonPath("$.email").value(merchantRequest.getEmail()));

        // Login merchant and extract token
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
        MerchantUpdateDTO updateDTO = new MerchantUpdateDTO();
        updateDTO.setEmail("updated_" + merchantRequest.getEmail());
        updateDTO.setFullName("Updated Merchant");
        updateDTO.setCardID("NEWMERCHANTCARD123");
        updateDTO.setFingerprintID("NEWMERCHANTFINGERPRINT123");

        mockMvc.perform(put("/api/merchant/profile")
                        .header("Authorization", "Bearer " + authToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(updateDTO.getEmail()))
                .andExpect(jsonPath("$.fullName").value(updateDTO.getFullName()));

        // Get profile and verify update
        mockMvc.perform(get("/api/merchant/profile")
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value(updateDTO.getEmail()))
                .andExpect(jsonPath("$.fullName").value(updateDTO.getFullName()));

        // Delete profile
        mockMvc.perform(delete("/api/merchant/profile")
                        .header("Authorization", "Bearer " + authToken))
                .andExpect(status().isOk());

        // Verify login fails after deletion
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isUnauthorized());
    }
}
