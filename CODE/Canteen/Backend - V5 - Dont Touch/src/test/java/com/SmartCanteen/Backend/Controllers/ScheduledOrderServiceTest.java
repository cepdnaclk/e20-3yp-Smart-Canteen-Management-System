package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.CartItemDTO;
import com.SmartCanteen.Backend.DTOs.ScheduledOrderDTO;
import com.SmartCanteen.Backend.Repositories.ScheduledOrderRepository;
import com.SmartCanteen.Backend.Services.ScheduledOrderService;
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

    @Test
    void scheduleOrder_ShouldPersist() {
        Long userId = 1L;
        ScheduledOrderDTO dto = new ScheduledOrderDTO();
        dto.setUserId(userId);
        dto.setScheduledTime(LocalDateTime.now().plusHours(1));
        dto.setItems(List.of(new CartItemDTO(1L, 2)));
        ScheduledOrderDTO scheduled = scheduledOrderService.scheduleOrder(userId, dto);
        assertThat(scheduled.getScheduledTime()).isNotNull();
    }
}
