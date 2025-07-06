//package com.SmartCanteen.Backend.Repositories;
//
//import com.SmartCanteen.Backend.Entities.Order;
//import com.SmartCanteen.Backend.Entities.Customer;
//import com.SmartCanteen.Backend.Entities.OrderStatus;
//import org.springframework.data.jpa.repository.JpaRepository;
//
//import java.time.LocalDateTime;
//import java.util.Collection;
//import java.util.List;
//import java.util.Optional;
//
//public interface OrderRepository extends JpaRepository<Order, Long> {
//    List<Order> findByCustomer(Customer customer);
//    List<Order> findByOrderTimeBetween(LocalDateTime start, LocalDateTime end);
//    Optional<Order> findById(Long id);
//    List<Order> findByStatus(OrderStatus status);
//
//
//}
package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.Order;
import com.SmartCanteen.Backend.Entities.Customer;
import com.SmartCanteen.Backend.Entities.OrderStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByCustomer(Customer customer);
    List<Order> findByStatus(OrderStatus status);

    // --- NEW: Queries for Reporting ---
    @Query("SELECT o FROM Order o JOIN o.items i JOIN MenuItem mi ON KEY(i) = mi.id WHERE mi.category.merchant.id = :merchantId AND o.status = 'COMPLETED' AND FUNCTION('DATE', o.orderTime) = :date")
    List<Order> findCompletedOrdersByMerchantAndDate(@Param("merchantId") Long merchantId, @Param("date") LocalDate date);

    @Query("SELECT o FROM Order o JOIN o.items i JOIN MenuItem mi ON KEY(i) = mi.id WHERE mi.category.merchant.id = :merchantId AND o.status = 'COMPLETED' AND FUNCTION('DATE', o.orderTime) BETWEEN :startDate AND :endDate")
    List<Order> findCompletedOrdersByMerchantAndDateRange(@Param("merchantId") Long merchantId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);

    // Add this method to OrderRepository.java
    @Query("SELECT o FROM Order o WHERE o.status = 'COMPLETED' AND FUNCTION('DATE', o.orderTime) BETWEEN :startDate AND :endDate")
    List<Order> findCompletedOrdersByDateRange(@Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
}