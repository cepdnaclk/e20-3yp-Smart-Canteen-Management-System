package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.CreditTopUpRequestDTO;
import com.SmartCanteen.Backend.DTOs.TopUpRequestDTO;
import com.SmartCanteen.Backend.Entities.*;
import com.SmartCanteen.Backend.Repositories.CustomerRepository;
import com.SmartCanteen.Backend.Repositories.MerchantRepository;
import com.SmartCanteen.Backend.Repositories.UserRepository;
import com.SmartCanteen.Backend.Security.UserPrincipal;
import com.SmartCanteen.Backend.Services.CreditTopUpRequestService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/topup")
@RequiredArgsConstructor
public class CreditTopUpController {

    private final CreditTopUpRequestService topUpRequestService;
    private final UserRepository userRepository;
    private final CustomerRepository customerRepository;
    private final MerchantRepository merchantRepository;

    private final CreditTopUpRequestService creditTopUpRequestService;


    @PostMapping("/request")
//    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<CreditTopUpRequestDTO> createRequest(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody TopUpRequestDTO dto) {
        Long customerId = getUserIdFromUserDetails(userDetails);
        CreditTopUpRequestDTO response = topUpRequestService.createTopUpRequest(customerId, dto.getAmount());
        return ResponseEntity.ok(response);
    }




    @GetMapping("/pending")
   // @PreAuthorize("hasRole('MERCHANT')")
    public ResponseEntity<List<CreditTopUpRequestDTO>> getPendingRequests() {
        List<CreditTopUpRequestDTO> requests = topUpRequestService.getAllPendingRequests();
        return ResponseEntity.ok(requests);
    }



    @PostMapping("/respond/{requestId}")
    //@PreAuthorize("hasRole('MERCHANT')")
    public ResponseEntity<?> respondRequest(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long requestId,
            @RequestParam boolean approve,
            @RequestParam String pin) {
        try {
            Long merchantId = getUserIdFromUserDetails(userDetails);
            CreditTopUpRequestDTO response = topUpRequestService.respondToRequest(merchantId, requestId, approve, pin);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            // Return 400 with error message
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(
                    Map.of("error", e.getMessage())
            );
        }
    }




    // Corrected method to extract user ID from UserDetails
    private Long getUserIdFromUserDetails(UserDetails userDetails) {
        if (userDetails instanceof UserPrincipal) {
            return ((UserPrincipal) userDetails).getId(); // Use UserPrincipal if available
        } else {
            // Fallback: get user by email (username is email in your setup)
            String email = userDetails.getUsername();
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found with email: " + email));
            return user.getId();
        }
    }
    @GetMapping("/balance")
//    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<BigDecimal> getCustomerBalance(@AuthenticationPrincipal UserDetails userDetails) {
        Long customerId = getUserIdFromUserDetails(userDetails);
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found"));
        return ResponseEntity.ok(customer.getCreditBalance());
    }

    // In CreditTopUpController.java

    @GetMapping("/my-requests")
  //  @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<List<CreditTopUpRequestDTO>> getMyRequests(@AuthenticationPrincipal UserDetails userDetails) {
        Long customerId = getUserIdFromUserDetails(userDetails);
        List<CreditTopUpRequestDTO> requests = topUpRequestService.getRequestsForCustomer(customerId);
        return ResponseEntity.ok(requests);
    }

    @DeleteMapping("/request/{requestId}")
   // @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<Void> deleteRequest(@AuthenticationPrincipal UserDetails userDetails, @PathVariable Long requestId) {
        Long customerId = getUserIdFromUserDetails(userDetails);
        topUpRequestService.deleteRequestByCustomer(requestId, customerId);
        return ResponseEntity.noContent().build();
    }





}
