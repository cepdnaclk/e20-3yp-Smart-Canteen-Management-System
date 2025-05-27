package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.CartDTO;
import com.SmartCanteen.Backend.DTOs.CartItemDTO;
import com.SmartCanteen.Backend.Entities.Customer;
import com.SmartCanteen.Backend.Repositories.CartRepository;
import com.SmartCanteen.Backend.Repositories.CustomerRepository;
import com.SmartCanteen.Backend.Services.CartService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
public class CartServiceTest {
    @Autowired
    private CartService cartService;
    @Autowired
    private CartRepository cartRepository;
    @Autowired
    private CustomerRepository customerRepository;

    private Long userId;

    @BeforeEach
    void setup() {
        // Create a test customer and use its ID
        Customer customer = new Customer();
        customer.setUsername("testuser_" + System.currentTimeMillis());
        customer.setPassword("testpass");
        customer.setEmail("test" + System.currentTimeMillis() + "@example.com");
        customer.setFullName("Test User");
        customer.setCreditBalance(BigDecimal.valueOf(100.0));
        customer = customerRepository.save(customer);
        userId = customer.getId();
    }

    @Test
    void addItemToCart_ShouldAddItem() {
        CartItemDTO item = new CartItemDTO(1L, 2); // Assumes menu item 1 exists; create one if needed in your setup
        CartDTO cart = cartService.addItem(userId, item);
        assertThat(cart.getItems()).hasSize(1);
        assertThat(cart.getItems().get(0).getMenuItemId()).isEqualTo(1L);
    }
}
