package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.CreditTopUpRequestDTO;
import com.SmartCanteen.Backend.Entities.CreditTopUpRequest;
import com.SmartCanteen.Backend.Entities.Customer;
import com.SmartCanteen.Backend.Entities.Merchant;
import com.SmartCanteen.Backend.Entities.RequestStatus;
import com.SmartCanteen.Backend.Repositories.CreditTopUpRequestRepository;
import com.SmartCanteen.Backend.Repositories.CustomerRepository;
import com.SmartCanteen.Backend.Repositories.MerchantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class CreditTopUpRequestServiceImpl implements CreditTopUpRequestService {

    private final CreditTopUpRequestRepository requestRepository;
    private final CustomerRepository customerRepository;
    private final MerchantRepository merchantRepository;

    @Override
    public CreditTopUpRequestDTO createTopUpRequest(Long customerId, BigDecimal amount) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new RuntimeException("Customer not found"));

        Merchant merchant = merchantRepository.findAll().stream().findFirst()
                .orElseThrow(() -> new RuntimeException("No merchants available"));

        CreditTopUpRequest request = new CreditTopUpRequest();
        request.setCustomer(customer);
        request.setMerchant(merchant);
        request.setAmount(amount);
        request.setStatus(RequestStatus.PENDING);
        request.setRequestTime(LocalDateTime.now());

        CreditTopUpRequest saved = requestRepository.save(request);

        return mapToDto(saved);
    }

    @Override
    public List<CreditTopUpRequestDTO> getPendingRequestsForMerchant(Long merchantId) {
        List<CreditTopUpRequest> requests = requestRepository.findByMerchantIdAndStatus(merchantId, RequestStatus.PENDING);
        return requests.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Override
    public CreditTopUpRequestDTO respondToRequest(Long merchantId, Long requestId, boolean approve) {
        CreditTopUpRequest request = requestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Request not found"));

        if (!request.getMerchant().getId().equals(merchantId)) {
            throw new RuntimeException("Not authorized to respond to this request");
        }

        if (request.getStatus() != RequestStatus.PENDING) {
            throw new RuntimeException("Request already processed");
        }

        if (approve) {
            request.setStatus(RequestStatus.APPROVED);
            Customer customer = request.getCustomer();
            customer.setCreditBalance(customer.getCreditBalance().add(request.getAmount()));
            customerRepository.save(customer);
        } else {
            request.setStatus(RequestStatus.REJECTED);
        }

        request.setResponseTime(LocalDateTime.now());
        CreditTopUpRequest updated = requestRepository.save(request);

        return mapToDto(updated);
    }

    private CreditTopUpRequestDTO mapToDto(CreditTopUpRequest request) {
        CreditTopUpRequestDTO dto = new CreditTopUpRequestDTO();
        dto.setId(request.getId());
        dto.setCustomerId(request.getCustomer().getId());
        dto.setMerchantId(request.getMerchant() != null ? request.getMerchant().getId() : null);
        dto.setAmount(request.getAmount());
        dto.setStatus(request.getStatus().name());
        dto.setRequestTime(request.getRequestTime());
        dto.setResponseTime(request.getResponseTime());
        return dto;
    }
}
