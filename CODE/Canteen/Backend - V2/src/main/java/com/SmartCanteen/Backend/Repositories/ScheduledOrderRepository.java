package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.ScheduledOrder;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface ScheduledOrderRepository extends JpaRepository<ScheduledOrder, Long> {
    List<ScheduledOrder> findByScheduledTimeBeforeAndProcessedFalse(LocalDateTime time);
}
