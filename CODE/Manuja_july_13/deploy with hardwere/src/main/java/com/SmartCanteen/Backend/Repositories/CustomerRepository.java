package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.Customer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;


// In CustomerRepository.java
public interface CustomerRepository extends JpaRepository<Customer, Long> {
    @Query("SELECT c FROM Customer c WHERE c.email = :email")
    Optional<Customer> findByEmail(@Param("email") String email);

    Optional<Customer> findByUsername(String username);

    Optional<Customer> findByCardID(String cardid);

}
