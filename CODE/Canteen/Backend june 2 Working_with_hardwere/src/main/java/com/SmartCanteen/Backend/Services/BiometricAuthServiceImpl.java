package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.*;
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

@Slf4j
@Service
public class BiometricAuthServiceImpl implements BiometricAuthService {

    private final CustomerRepository customerRepository;
    private final RestTemplate restTemplate;

    @Value("${esp32.ip:192.168.8.192}")
    private String esp32Ip;

    @Autowired
    public BiometricAuthServiceImpl(CustomerRepository customerRepository,
                                    RestTemplate restTemplate) {
        this.customerRepository = customerRepository;
        this.restTemplate = restTemplate;
    }

    @Override
    public InitiateResponseDTO initiateVerification(String email, Long orderId, String token) {
        try {
            User customer = customerRepository.findByEmail(email)
                    .orElseThrow(() -> new CustomerNotFoundException("Customer not found"));

            if (customer.getFingerprintID() == null || customer.getFingerprintID().isEmpty()) {
                throw new FingerprintNotRegisteredException("Fingerprint not registered");
            }

            sendToESP32(email, orderId, token);

            return InitiateResponseDTO.builder()
                    .initiated(true)
                    .message("Verification initiated")
                    .build();

        } catch (Exception e) {
            return InitiateResponseDTO.builder()
                    .initiated(false)
                    .message("Initiation failed: " + e.getMessage())
                    .build();
        }
    }

    private void sendToESP32(String email, Long orderId, String token) {
        String url = "http://" + esp32Ip + "/verify";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_PLAIN); // or APPLICATION_JSON if ESP32 expects JSON
        headers.set("Authorization", "Bearer " + token);

        String jsonPayload = String.format("{\"email\":\"%s\", \"orderId\":%d}", email, orderId);

        // 🔍 Log the full JSON being sent
        log.info("Sending JSON to ESP32: {}", jsonPayload);

        HttpEntity<String> entity = new HttpEntity<>(jsonPayload, headers);
        ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, entity, String.class);

        log.info("ESP32 response: Status={} Body={}", response.getStatusCode(), response.getBody());
    }


    @Override
    public BiometricAuthResponseDTO confirmVerification(String email, Long orderId,
                                                        int confidence, String scannedId,
                                                        String token) {
        try {
            User customer = customerRepository.findByEmail(email)
                    .orElseThrow(() -> new CustomerNotFoundException("Customer not found"));

            if (!customer.getFingerprintID().equals(scannedId)) {
                return BiometricAuthResponseDTO.builder()
                        .authenticated(false)
                        .message("Fingerprint mismatch")
                        .orderStatus(OrderStatus.FAILED)
                        .build();
            }

            if (confidence < 50) {
                return BiometricAuthResponseDTO.builder()
                        .authenticated(false)
                        .message("Low confidence: " + confidence)
                        .orderStatus(OrderStatus.FAILED)
                        .build();
            }

            return BiometricAuthResponseDTO.builder()
                    .authenticated(true)
                    .message("Authentication successful")
                    .orderStatus(OrderStatus.VERIFIED)
                    .build();

        } catch (Exception e) {
            return BiometricAuthResponseDTO.builder()
                    .authenticated(false)
                    .message("Confirmation failed: " + e.getMessage())
                    .orderStatus(OrderStatus.FAILED)
                    .build();
        }
    }
}
