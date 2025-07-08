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

        // Generate 4-digit PIN
        String pin = String.format("%04d", (int)(Math.random() * 10000));

        CreditTopUpRequest request = new CreditTopUpRequest();
        request.setCustomer(customer);
        request.setAmount(amount);
        request.setStatus(RequestStatus.PENDING);
        request.setRequestTime(LocalDateTime.now());
        request.setPin(pin);

        CreditTopUpRequest saved = requestRepository.save(request);
        return mapToDto(saved);
    }

    @Override
    public CreditTopUpRequestDTO respondToRequest(Long merchantId, Long requestId, boolean approve, String pin) {
        CreditTopUpRequest request = requestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Request not found"));

        System.out.println("Stored PIN: '" + request.getPin() + "'");
        System.out.println("Input PIN: '" + pin + "'");


        // PIN Validation
        if (!request.getPin().trim().equalsIgnoreCase(pin.trim())) {
            throw new RuntimeException("Invalid PIN");
        }


        if (request.getStatus() != RequestStatus.PENDING) {
            throw new RuntimeException("Request already processed");
        }

        Merchant merchant = merchantRepository.findById(merchantId)
                .orElseThrow(() -> new RuntimeException("Merchant not found"));

        // Assign the merchant who responds
        request.setMerchant(merchant);

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

    @Override
    public List<CreditTopUpRequestDTO> getAllPendingRequests() {
        List<CreditTopUpRequest> requests = requestRepository.findByStatus(RequestStatus.PENDING);
        return requests.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Override
    public List<CreditTopUpRequestDTO> getRequestsForCustomer(Long customerId) {
        List<CreditTopUpRequest> requests = requestRepository.findByCustomerId(customerId);
        return requests.stream().map(this::mapToDto).collect(Collectors.toList());
    }

    @Override
    public void deleteRequestByCustomer(Long requestId, Long customerId) {
        CreditTopUpRequest request = requestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Request not found"));
        if (!request.getCustomer().getId().equals(customerId)) {
            throw new RuntimeException("Not authorized to delete this request");
        }
        if (request.getStatus() != RequestStatus.PENDING) {
            throw new RuntimeException("Only pending requests can be deleted");
        }
        requestRepository.deleteById(requestId);
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
        dto.setPin(request.getPin());
        return dto;
    }
}
