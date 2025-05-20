package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.CustomerRequestDTO;
import com.SmartCanteen.Backend.DTOs.LoginRequestDTO;
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
public class AuthControllerLoginTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    private CustomerRequestDTO customerRequest;
    private LoginRequestDTO loginRequest;

    @BeforeEach
    public void setup() {
        // Clear users before each test to avoid duplicates
        userRepository.deleteAll();

        // Use a fixed username for clarity
        String username = "loginuser";

        customerRequest = new CustomerRequestDTO();
        customerRequest.setUsername(username);
        customerRequest.setEmail(username + "@example.com");
        customerRequest.setFullName("Login User");
        customerRequest.setPassword("password123");
        customerRequest.setCardID("CARDLOGIN1");
        customerRequest.setFingerprintID("FINGERPRINTLOGIN1");
        customerRequest.setCreditBalance(50.0);

        loginRequest = new LoginRequestDTO();
        loginRequest.setUsername(username);
        loginRequest.setPassword("password123");
    }

    @Test
    public void login_ValidCredentials_ShouldReturnToken() throws Exception {
        // Register user first
        mockMvc.perform(post("/api/auth/register/customer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(customerRequest)))
                .andExpect(status().isOk());

        // Then login
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.username").value("loginuser"))
                .andExpect(jsonPath("$.role").value("CUSTOMER"));
    }

    @Test
    public void login_InvalidPassword_ShouldReturnUnauthorized() throws Exception {
        // Register user first
        mockMvc.perform(post("/api/auth/register/customer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(customerRequest)))
                .andExpect(status().isOk());

        // Attempt login with wrong password
        loginRequest.setPassword("wrongpassword");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid username or password"));
    }

    @Test
    public void login_NonExistentUser_ShouldReturnUnauthorized() throws Exception {
        // Attempt login with a username that does not exist
        loginRequest.setUsername("nonexistentuser");
        loginRequest.setPassword("anyPassword");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid username or password"));
    }
}
