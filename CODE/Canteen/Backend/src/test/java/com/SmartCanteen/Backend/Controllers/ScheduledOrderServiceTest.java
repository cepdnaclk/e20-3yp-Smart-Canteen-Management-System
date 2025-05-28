package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.CartItemDTO;
import com.SmartCanteen.Backend.DTOs.ScheduledOrderDTO;
import com.SmartCanteen.Backend.Entities.Customer;
import com.SmartCanteen.Backend.Repositories.CustomerRepository;
import com.SmartCanteen.Backend.Repositories.ScheduledOrderRepository;
import com.SmartCanteen.Backend.Services.ScheduledOrderService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
public class ScheduledOrderServiceTest {
    @Autowired
    private ScheduledOrderService scheduledOrderService;
    @Autowired
    private ScheduledOrderRepository scheduledOrderRepository;
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
        // Set other required fields if needed
        customer = customerRepository.save(customer);
        userId = customer.getId();
    }

    @Test
    void scheduleOrder_ShouldPersist() {
        ScheduledOrderDTO dto = new ScheduledOrderDTO();
        dto.setUserId(userId);
        dto.setScheduledTime(LocalDateTime.now().plusHours(1));
        dto.setItems(List.of(new CartItemDTO(1L, 2))); // Assumes menu item 1 exists, or mock as needed

        ScheduledOrderDTO scheduled = scheduledOrderService.scheduleOrder(userId, dto);

        assertThat(scheduled.getScheduledTime()).isNotNull();
        assertThat(scheduled.getUserId()).isEqualTo(userId);
    }
}
