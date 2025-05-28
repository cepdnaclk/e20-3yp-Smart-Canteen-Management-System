package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.CreditTopUpRequestDTO;
import com.SmartCanteen.Backend.DTOs.TopUpRequestDTO;
import com.SmartCanteen.Backend.Entities.User;
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

import java.util.List;

@RestController
@RequestMapping("/api/topup")
@RequiredArgsConstructor
public class CreditTopUpController {

    private final CreditTopUpRequestService topUpRequestService;
    private final UserRepository userRepository;

    @PostMapping("/request")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<CreditTopUpRequestDTO> createRequest(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody TopUpRequestDTO dto) {
        Long customerId = getUserIdFromUserDetails(userDetails);
        CreditTopUpRequestDTO response = topUpRequestService.createTopUpRequest(customerId, dto.getAmount());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/pending")
    @PreAuthorize("hasRole('MERCHANT')")
    public ResponseEntity<List<CreditTopUpRequestDTO>> getPendingRequests(
            @AuthenticationPrincipal UserDetails userDetails) {
        Long merchantId = getUserIdFromUserDetails(userDetails);
        List<CreditTopUpRequestDTO> requests = topUpRequestService.getPendingRequestsForMerchant(merchantId);
        return ResponseEntity.ok(requests);
    }

    @PostMapping("/respond/{requestId}")
    @PreAuthorize("hasRole('MERCHANT')")
    public ResponseEntity<CreditTopUpRequestDTO> respondRequest(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long requestId,
            @RequestParam boolean approve) {
        Long merchantId = getUserIdFromUserDetails(userDetails);
        CreditTopUpRequestDTO response = topUpRequestService.respondToRequest(merchantId, requestId, approve);
        return ResponseEntity.ok(response);
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
}
