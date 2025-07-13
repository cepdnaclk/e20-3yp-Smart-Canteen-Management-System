package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.BiometricAuthResponseDTO;
import com.SmartCanteen.Backend.DTOs.InitiateResponseDTO;
import com.SmartCanteen.Backend.Entities.OrderStatus;
import com.SmartCanteen.Backend.Entities.User;
import com.SmartCanteen.Backend.Exceptions.CustomerNotFoundException;
import com.SmartCanteen.Backend.Exceptions.FingerprintNotRegisteredException;
import com.SmartCanteen.Backend.Repositories.CustomerRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.ResourceAccessException; // Import for network errors

import jakarta.annotation.PostConstruct; // Import for @PostConstruct
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit; // For poll with timeout

@Slf4j
@Service
public class BiometricAuthServiceImpl implements BiometricAuthService {

    private final CustomerRepository customerRepository;
    private final RestTemplate restTemplate;

    // These values will now point to the UI Client's IP and listening port
    @Value("${ui.client.ip:100.93.177.42}") // IP of the UI Client (which is also the RPi Tailscale IP)
    private String uiClientIp;

    @Value("${ui.client.port:5001}") // Changed to 5000, as per Flask app configuration
    private String uiClientPort;

    // --- New: Queue for biometric verification requests ---
    private final BlockingQueue<BiometricRequest> biometricRequestQueue = new LinkedBlockingQueue<>();
    // A flag to indicate if a verification process is currently active (optional, for internal state tracking)
    private volatile boolean isVerificationInProgress = false;

    // Inner class to hold request details
    private static class BiometricRequest {
        String email;
        Long orderId;
        String token;

        public BiometricRequest(String email, Long orderId, String token) {
            this.email = email;
            this.orderId = orderId;
            this.token = token;
        }
    }

    @Autowired
    public BiometricAuthServiceImpl(CustomerRepository customerRepository,
                                    RestTemplate restTemplate) {
        this.customerRepository = customerRepository;
        this.restTemplate = restTemplate;
    }

    // --- New: Start a dedicated thread to process the queue after bean initialization ---
    @PostConstruct
    public void init() {
        Thread queueProcessorThread = new Thread(this::processBiometricQueue);
        queueProcessorThread.setDaemon(true); // Allow application to exit if this is the only thread left
        queueProcessorThread.setName("BiometricQueueProcessor");
        queueProcessorThread.start();
        log.info("Biometric verification queue processor started.");
    }

    @Override
    public InitiateResponseDTO initiateVerification(String email, Long orderId, String token) {
        try {
            User customer = customerRepository.findByEmail(email)
                    .orElseThrow(() -> new CustomerNotFoundException("Customer not found"));

            if (customer.getFingerprintID() == null || customer.getFingerprintID().isEmpty()) {
                throw new FingerprintNotRegisteredException("Fingerprint not registered");
            }

            // --- Modified: Add the request to the queue instead of sending immediately ---
            BiometricRequest request = new BiometricRequest(email, orderId, token);
            boolean added = biometricRequestQueue.offer(request); // offer returns false if queue is full (unlikely with LinkedBlockingQueue)

            if (added) {
                log.info("Biometric verification request for email: {} orderId: {} added to queue.", email, orderId);
                return InitiateResponseDTO.builder()
                        .initiated(true)
                        .message("Verification initiated and queued. Please wait for your turn.") // Updated message
                        .build();
            } else {
                // This scenario is rare with LinkedBlockingQueue unless it's configured with a capacity
                log.warn("Failed to add biometric verification request for email: {} orderId: {} to queue (queue might be full).", email, orderId);
                return InitiateResponseDTO.builder()
                        .initiated(false)
                        .message("Verification initiation failed: System is busy, please try again.")
                        .build();
            }

        } catch (CustomerNotFoundException | FingerprintNotRegisteredException e) {
            log.error("Initiation failed for email: {} orderId: {}. Reason: {}", email, orderId, e.getMessage());
            return InitiateResponseDTO.builder()
                    .initiated(false)
                    .message("Initiation failed: " + e.getMessage())
                    .build();
        } catch (Exception e) { // Catch broader exceptions for network issues etc.
            log.error("Initiation failed for email: {} orderId: {}. Unexpected error: {}", email, orderId, e.getMessage(), e);
            return InitiateResponseDTO.builder()
                    .initiated(false)
                    .message("Initiation failed: An unexpected error occurred.") // Simplified message for unexpected errors
                    .build();
        }
    }

    // --- New: Separate method to process items from the queue ---
    private void processBiometricQueue() {
        while (!Thread.currentThread().isInterrupted()) {
            try {
                // Poll for a request, wait for a short period if queue is empty
                BiometricRequest request = biometricRequestQueue.poll(100, TimeUnit.MILLISECONDS);
                if (request != null) {
                    // Set flag to indicate a process is active
                    isVerificationInProgress = true;
                    try {
                        log.info("Processing biometric request from queue for email: {} orderId: {}", request.email, request.orderId);
                        // Call the original method to send the trigger to the UI Client
                        triggerBiometricOnUiClient(request.email, request.orderId, request.token);
                        // At this point, the request has been sent to the UI Client.
                        // The system now waits for ESP32 to send back a /biometric/confirm
                        // This service shouldn't block here.
                    } catch (ResourceAccessException e) {
                        log.error("Network error when processing queued biometric request for email: {} orderId: {}: {}", request.email, request.orderId, e.getMessage());
                        // Handle network-specific errors for queued requests
                        // You might want to implement retry logic or a more robust error notification here
                    } catch (Exception e) {
                        log.error("Unexpected error when processing queued biometric request for email: {} orderId: {}: {}", request.email, request.orderId, e.getMessage(), e);
                        // Handle other unexpected errors for queued requests
                    } finally {
                        // Crucially, reset the flag AFTER the UI Client interaction is complete or failed
                        // This allows the next request in the queue to proceed.
                        isVerificationInProgress = false;
                    }
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt(); // Restore interrupt status
                log.warn("Biometric queue processor interrupted. Shutting down.");
                break;
            }
        }
    }

    // This method now sends the request directly to the UI Client using HTTP
    private void triggerBiometricOnUiClient(String email, Long orderId, String token) {
        // Construct the URL for the UI Client's biometric trigger endpoint using HTTP
        // As discussed, the Python Flask app listens on port 5000 and has endpoint /api/merchant/request-biometrics
        String url = String.format("http://%s:%s/trigger-biometric", uiClientIp, uiClientPort);

        HttpHeaders headers = new HttpHeaders();
        // The UI Client's endpoint will expect JSON
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Authorization", "Bearer " + token); // Pass the token if UI Client needs it for forwarding decisions

        // Create the JSON payload for the UI Client to forward to ESP32
        String jsonPayload = String.format("{\"email\":\"%s\"}", email); // Removed orderId as per Python's /request-biometrics endpoint definition

        log.info("Sending JSON to UI Client at {}: {}", url, jsonPayload);

        HttpEntity<String> entity = new HttpEntity<>(jsonPayload, headers);

        try {
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, entity, String.class);
            log.info("UI Client response for biometric trigger: Status={} Body={}", response.getStatusCode(), response.getBody());
        } catch (ResourceAccessException e) {
            // This specifically catches network-related issues like "No route to host", connection refused, etc.
            log.error("Failed to send request to UI Client at {}: Network/Connection error: {}", url, e.getMessage());
            throw new RuntimeException("Failed to communicate with UI Client. Check network and UI Client status.", e);
        } catch (Exception e) {
            log.error("Failed to send request to UI Client at {}: Unexpected error: {}", url, e.getMessage());
            throw new RuntimeException("Failed to communicate with UI Client", e);
        }
    }

    @Override
    public BiometricAuthResponseDTO confirmVerification(String email, Long orderId,
                                                        int confidence, String scannedId,
                                                        String token) {
        try {
            User customer = customerRepository.findByEmail(email)
                    .orElseThrow(() -> new CustomerNotFoundException("Customer not found"));


            if (!customer.getFingerprintID().equals(scannedId)) {
                log.warn("Fingerprint mismatch for email: {}. Expected ID: {}, Scanned ID: {}",
                        email, customer.getFingerprintID(), scannedId);
                return BiometricAuthResponseDTO.builder()
                        .authenticated(false)
                        .message("Fingerprint mismatch")
                        .orderStatus(OrderStatus.FAILED)
                        .build();
            }

            // The ESP32 code has MIN_CONFIDENCE = 50.
            // Ensure this matches your backend's expectation for authentication.
            if (confidence < 50) {
                log.warn("Low confidence for email: {}. Confidence: {}", email, confidence);
                return BiometricAuthResponseDTO.builder()
                        .authenticated(false)
                        .message("Low confidence: " + confidence)
                        .orderStatus(OrderStatus.FAILED)
                        .build();
            }

            log.info("Authentication successful for email: {} orderId: {}", email, orderId);
            return BiometricAuthResponseDTO.builder()
                    .authenticated(true)
                    .message("Authentication successful")
                    .orderStatus(OrderStatus.VERIFIED) // Or COMPLETED, depending on your flow
                    .build();

        } catch (CustomerNotFoundException e) {
            log.error("Customer not found during confirmation for email: {}", email, e);
            return BiometricAuthResponseDTO.builder()
                    .authenticated(false)
                    .message("Confirmation failed: " + e.getMessage())
                    .orderStatus(OrderStatus.FAILED)
                    .build();
        } catch (Exception e) {
            log.error("An unexpected error occurred during confirmation for email: {} orderId: {}", email, orderId, e);
            return BiometricAuthResponseDTO.builder()
                    .authenticated(false)
                    .message("Confirmation failed: " + e.getMessage())
                    .orderStatus(OrderStatus.FAILED)
                    .build();
        }
    }
}