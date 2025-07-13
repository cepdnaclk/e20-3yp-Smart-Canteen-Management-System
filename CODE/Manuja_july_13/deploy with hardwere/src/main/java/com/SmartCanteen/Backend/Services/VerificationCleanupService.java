package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.Repositories.TemporaryUserRepository;
import com.SmartCanteen.Backend.Repositories.VerificationCodeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class VerificationCleanupService {
    private final VerificationCodeRepository verificationCodeRepository;
    private final TemporaryUserRepository temporary1UserRepository; // Fix typo if present

    @Scheduled(fixedRate = 3600000) // Every hour
    public void cleanupExpiredVerificationCodesAndUsers() {
        verificationCodeRepository.deleteByExpiresAtBefore(LocalDateTime.now());

    }


}
