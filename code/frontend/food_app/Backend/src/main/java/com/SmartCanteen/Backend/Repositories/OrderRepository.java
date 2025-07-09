package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.Order;
import com.SmartCanteen.Backend.Entities.Customer;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByCustomer(Customer customer);
}
