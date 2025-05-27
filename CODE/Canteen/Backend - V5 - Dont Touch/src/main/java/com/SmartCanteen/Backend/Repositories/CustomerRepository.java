package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.Customer;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface CustomerRepository extends JpaRepository<Customer, Long> {

    Optional<Customer> findByUsername(String username); // Keep this

    // DO NOT ADD findById(String id).  It is automatically provided by JpaRepository<Customer, Long>
}
