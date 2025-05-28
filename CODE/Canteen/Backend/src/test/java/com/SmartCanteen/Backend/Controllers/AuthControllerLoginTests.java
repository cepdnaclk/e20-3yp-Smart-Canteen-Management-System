package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.*;
import com.SmartCanteen.Backend.Repositories.*;
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

    @Autowired
    private CustomerRepository customer1Repository;

    @Autowired
    private MerchantRepository merchantRepository;

    @Autowired
    private CreditTopUpRequestRepository creditTopUpRequestRepository;

    private CustomerRequestDTO customerRequest;
    private LoginRequestDTO loginRequest;

    @BeforeEach
    public void setup() {
        creditTopUpRequestRepository.deleteAll();
        customer1Repository.deleteAll();
        merchantRepository.deleteAll();
        userRepository.deleteAll();

        String username = "loginuser1";
        customerRequest = new CustomerRequestDTO();
        customerRequest.setUsername(username);
        customerRequest.setEmail(username + "@example.com");
        customerRequest.setFullName("Login User1");
        customerRequest.setPassword("password1232");
        customerRequest.setCardID("CARDLOGIN1");
        customerRequest.setFingerprintID("FINGERPRINTLOGIN1");
        customerRequest.setCreditBalance(50.0);

        loginRequest = new LoginRequestDTO();
        loginRequest.setUsername(username);
        loginRequest.setPassword("password1232");
    }

    @Test
    public void login_ValidCredentials_ShouldReturnToken() throws Exception {
        mockMvc.perform(post("/api/auth/register/customer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(customerRequest)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.username").value("loginuser1"))
                .andExpect(jsonPath("$.role").value("CUSTOMER"));
    }

    @Test
    public void login_InvalidPassword_ShouldReturnUnauthorized() throws Exception {
        mockMvc.perform(post("/api/auth/register/customer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(customerRequest)))
                .andExpect(status().isOk());

        loginRequest.setPassword("wrongpassword");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid username or password"));
    }

    @Test
    public void login_NonExistentUser_ShouldReturnUnauthorized() throws Exception {
        loginRequest.setUsername("nonexistentuser");
        loginRequest.setPassword("anyPassword");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid username or password"));
    }

    @Test
    public void login_EmptyUsername_ShouldReturnBadRequest() throws Exception {
        loginRequest.setUsername("");
        loginRequest.setPassword("password1232");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void login_EmptyPassword_ShouldReturnBadRequest() throws Exception {
        loginRequest.setUsername("loginuser1");
        loginRequest.setPassword("");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isBadRequest());
    }
}
