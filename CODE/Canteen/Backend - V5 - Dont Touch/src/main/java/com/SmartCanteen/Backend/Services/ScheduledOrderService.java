package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.OrderDTO;
import com.SmartCanteen.Backend.DTOs.ScheduledOrderDTO;
import com.SmartCanteen.Backend.Entities.ScheduledOrder;
import com.SmartCanteen.Backend.Repositories.ScheduledOrderRepository;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ScheduledOrderService {
    private final ScheduledOrderRepository scheduledOrderRepository;
    private final OrderService orderService;
    private final NotificationService notificationService;
    private final ModelMapper modelMapper;

    public ScheduledOrderDTO scheduleOrder(Long userId, ScheduledOrderDTO dto) {
        ScheduledOrder order = new ScheduledOrder();
        order.setUserId(userId);
        order.setScheduledTime(dto.getScheduledTime());
        // Convert List<CartItemDTO> to your entity format if needed (if you want to store items)
        scheduledOrderRepository.save(order);
        notificationService.sendScheduledOrderNotification(userId, dto.getScheduledTime().toString());
        return modelMapper.map(order, ScheduledOrderDTO.class);
    }

    public List<ScheduledOrderDTO> getScheduledOrders(Long userId) {
        return scheduledOrderRepository.findByUserId(userId).stream()
                .map(order -> modelMapper.map(order, ScheduledOrderDTO.class))
                .collect(Collectors.toList());
    }

    public void cancelScheduledOrder(Long userId, Long id) {
        scheduledOrderRepository.deleteByIdAndUserId(id, userId);
    }
}
