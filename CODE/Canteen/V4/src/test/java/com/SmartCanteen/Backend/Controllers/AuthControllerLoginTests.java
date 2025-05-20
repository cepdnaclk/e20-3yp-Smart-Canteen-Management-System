package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.CustomerRequestDTO;
import com.SmartCanteen.Backend.DTOs.LoginRequestDTO;
import com.SmartCanteen.Backend.Repositories.CreditTopUpRequestRepository;
import com.SmartCanteen.Backend.Repositories.CustomerRepository;
import com.SmartCanteen.Backend.Repositories.MerchantRepository;
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

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private MerchantRepository merchantRepository;

    @Autowired
    private CreditTopUpRequestRepository creditTopUpRequestRepository;

    private CustomerRequestDTO customerRequest;
    private LoginRequestDTO loginRequest;

    @BeforeEach
    public void setup() {
        // Delete child tables/entities first to avoid FK constraint errors
        creditTopUpRequestRepository.deleteAll();
        // If you have other child tables, delete them here

        // Then delete parent tables/entities
        customerRepository.deleteAll();
        merchantRepository.deleteAll();
        userRepository.deleteAll();

        // Now set up your test data as before
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
                .andExpect(jsonPath("$.username").value("loginuser1"))
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
