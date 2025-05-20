package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.CreditTopUpRequest;
import com.SmartCanteen.Backend.Entities.RequestStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CreditTopUpRequestRepository extends JpaRepository<CreditTopUpRequest, Long> {

    List<CreditTopUpRequest> findByMerchantIdAndStatus(Long merchantId, RequestStatus status);
}
