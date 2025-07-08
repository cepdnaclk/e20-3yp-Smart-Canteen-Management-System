package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.Order;
import com.SmartCanteen.Backend.Entities.Customer;
import com.SmartCanteen.Backend.Entities.OrderStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByCustomer(Customer customer);
    List<Order> findByOrderTimeBetween(LocalDateTime start, LocalDateTime end);
    Optional<Order> findById(Long id);
    List<Order> findByStatus(OrderStatus status);


}
