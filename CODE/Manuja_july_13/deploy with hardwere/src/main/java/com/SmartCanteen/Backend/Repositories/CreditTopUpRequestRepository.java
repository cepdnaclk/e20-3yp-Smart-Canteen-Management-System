package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.DTOs.CreditTopUpRequestDTO;
import com.SmartCanteen.Backend.Entities.CreditTopUpRequest;
import com.SmartCanteen.Backend.Entities.RequestStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CreditTopUpRequestRepository extends JpaRepository<CreditTopUpRequest, Long> {
    List<CreditTopUpRequest> findByStatus(RequestStatus status);
    List<CreditTopUpRequest> findByCustomerId(Long customerId);
    // Add this method for finding by ID
    @Override
    Optional<CreditTopUpRequest> findById(Long id);

}
