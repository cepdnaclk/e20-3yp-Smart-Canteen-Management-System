package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.CreditTopUpRequestDTO;

import java.math.BigDecimal;
import java.util.List;

public interface CreditTopUpRequestService {
    CreditTopUpRequestDTO createTopUpRequest(Long customerId, BigDecimal amount);
    List<CreditTopUpRequestDTO> getPendingRequestsForMerchant(Long merchantId);
    CreditTopUpRequestDTO respondToRequest(Long merchantId, Long requestId, boolean approve);
}
