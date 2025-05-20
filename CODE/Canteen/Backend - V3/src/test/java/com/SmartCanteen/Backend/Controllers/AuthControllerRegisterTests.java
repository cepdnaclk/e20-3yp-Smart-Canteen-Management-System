package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.CustomerRequestDTO;
import com.SmartCanteen.Backend.Repositories.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class AuthControllerRegisterTests {

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    public void cleanDb() {
        userRepository.deleteAll();
    }


    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private CustomerRequestDTO validCustomer;

    @BeforeEach
    public void setup() {
        validCustomer = new CustomerRequestDTO();
        validCustomer.setUsername("testuser");
        validCustomer.setEmail("testuser@example.com");
        validCustomer.setFullName("Test User");
        validCustomer.setPassword("password123");
        validCustomer.setCardID("CARD123");
        validCustomer.setFingerprintID("FINGERPRINT123");
        validCustomer.setCreditBalance(100.0);
    }

    @Test
    public void registerCustomer_ValidInput_ShouldReturnOk() throws Exception {
        // Use unique username to avoid conflict
        validCustomer.setUsername("testuser_" + System.currentTimeMillis());
        validCustomer.setEmail("testuser_" + System.currentTimeMillis() + "@example.com");
        validCustomer.setFullName("Test User");

        mockMvc.perform(post("/api/auth/register/customer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validCustomer)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value(validCustomer.getUsername()))
                .andExpect(jsonPath("$.email").value(validCustomer.getEmail()))
                .andExpect(jsonPath("$.fullName").value(validCustomer.getFullName()))
                .andExpect(jsonPath("$.creditBalance").value(100.0));
    }


    @Test
    public void registerCustomer_InvalidEmail_ShouldReturnBadRequest() throws Exception {
        validCustomer.setEmail("invalid-email");

        mockMvc.perform(post("/api/auth/register/customer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validCustomer)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.email").value("Invalid email format"));
    }

    @Test
    public void registerCustomer_MissingUsername_ShouldReturnBadRequest() throws Exception {
        validCustomer.setUsername(null);

        mockMvc.perform(post("/api/auth/register/customer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validCustomer)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.username").value("Username is required"));
    }

    @Test
    public void registerCustomer_DuplicateUsername_ShouldReturnConflict() throws Exception {
        // First registration
        mockMvc.perform(post("/api/auth/register/customer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validCustomer)))
                .andExpect(status().isOk());

        // Duplicate registration
        mockMvc.perform(post("/api/auth/register/customer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validCustomer)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("Username is already taken"));
    }
}
