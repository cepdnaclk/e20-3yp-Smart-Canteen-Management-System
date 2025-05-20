package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.CreditTopUpRequestDTO;
import com.SmartCanteen.Backend.DTOs.TopUpRequestDTO;
import com.SmartCanteen.Backend.Entities.Customer;
import com.SmartCanteen.Backend.Entities.Merchant;
import com.SmartCanteen.Backend.Repositories.CreditTopUpRequestRepository;
import com.SmartCanteen.Backend.Repositories.CustomerRepository;
import com.SmartCanteen.Backend.Repositories.MerchantRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.UserRequestPostProcessor;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class CreditTopUpControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private MerchantRepository merchantRepository;

    @Autowired
    private CreditTopUpRequestRepository topUpRequestRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private Customer testCustomer;
    private Merchant testMerchant;

    private UserRequestPostProcessor customerUser;
    private UserRequestPostProcessor merchantUser;

    @BeforeEach
    public void setup() {
        topUpRequestRepository.deleteAll();
        customerRepository.deleteAll();
        merchantRepository.deleteAll();

        // Create test customer
        testCustomer = new Customer();
        testCustomer.setUsername("testcustomer");
        testCustomer.setPassword(passwordEncoder.encode("password"));
        testCustomer.setEmail("customer@example.com");
        testCustomer.setCreditBalance(BigDecimal.ZERO);
        customerRepository.save(testCustomer);

        // Create test merchant
        testMerchant = new Merchant();
        testMerchant.setUsername("testmerchant");
        testMerchant.setPassword(passwordEncoder.encode("password"));
        testMerchant.setEmail("merchant@example.com");
        merchantRepository.save(testMerchant);

        // Prepare mock users with roles
        customerUser = user(testCustomer.getUsername()).roles("CUSTOMER");
        merchantUser = user(testMerchant.getUsername()).roles("MERCHANT");
    }

    @Test
    public void testCreateTopUpRequestAndApprove() throws Exception {
        TopUpRequestDTO requestDTO = new TopUpRequestDTO();
        requestDTO.setAmount(BigDecimal.valueOf(100));

        // Customer creates top-up request
        String response = mockMvc.perform(post("/api/topup/request")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO))
                        .with(customerUser))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.amount").value(100))
                .andExpect(jsonPath("$.status").value("PENDING"))
                .andReturn()
                .getResponse()
                .getContentAsString();

        CreditTopUpRequestDTO createdRequest = objectMapper.readValue(response, CreditTopUpRequestDTO.class);

        // Merchant fetches pending requests
        mockMvc.perform(get("/api/topup/pending")
                        .with(merchantUser))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(createdRequest.getId()));

        // Merchant approves the request
        mockMvc.perform(post("/api/topup/respond/" + createdRequest.getId())
                        .param("approve", "true")
                        .with(merchantUser))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("APPROVED"));

        // Verify customer's credit balance updated
        Customer updatedCustomer = customerRepository.findById(testCustomer.getId()).orElseThrow();
        assertThat(updatedCustomer.getCreditBalance()).isEqualByComparingTo(BigDecimal.valueOf(100));
    }

    @Test
    public void testCreateTopUpRequestAndDecline() throws Exception {
        TopUpRequestDTO requestDTO = new TopUpRequestDTO();
        requestDTO.setAmount(BigDecimal.valueOf(50));

        // Customer creates top-up request
        String response = mockMvc.perform(post("/api/topup/request")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDTO))
                        .with(customerUser))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        CreditTopUpRequestDTO createdRequest = objectMapper.readValue(response, CreditTopUpRequestDTO.class);

        // Merchant declines the request
        mockMvc.perform(post("/api/topup/respond/" + createdRequest.getId())
                        .param("approve", "false")
                        .with(merchantUser))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REJECTED"));

        // Verify customer's credit balance remains zero
        Customer updatedCustomer = customerRepository.findById(testCustomer.getId()).orElseThrow();
        assertThat(updatedCustomer.getCreditBalance()).isEqualByComparingTo(BigDecimal.ZERO);
    }
}
