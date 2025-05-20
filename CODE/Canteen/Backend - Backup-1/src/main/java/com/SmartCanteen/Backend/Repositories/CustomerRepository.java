package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.Customer;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CustomerRepository extends JpaRepository<Customer, Long> {}
