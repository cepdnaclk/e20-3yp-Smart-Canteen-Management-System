package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.*;

public interface BiometricAuthService {
    InitiateResponseDTO initiateVerification(String email, Long orderId, String token);
    BiometricAuthResponseDTO confirmVerification(String email, Long orderId, int confidence,
                                                 String scannedId, String token);
}