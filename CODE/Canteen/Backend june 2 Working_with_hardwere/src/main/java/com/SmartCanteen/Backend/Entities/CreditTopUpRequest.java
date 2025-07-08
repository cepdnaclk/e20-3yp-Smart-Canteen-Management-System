package com.SmartCanteen.Backend.Entities;

import jakarta.persistence.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Data
public class CreditTopUpRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "customer_id", referencedColumnName = "user_id")
    private Customer customer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "merchant_id", referencedColumnName = "user_id")
    private Merchant merchant;

    @Column(nullable = false)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RequestStatus status;

    private LocalDateTime requestTime;

    private LocalDateTime responseTime;


    // In CreditTopUpRequest.java

    @Column(nullable = false)
    private String pin; // 4-digit PIN as string


    @PrePersist
    public void prePersist() {
        requestTime = LocalDateTime.now();
        if (status == null) {
            status = RequestStatus.PENDING;
        }
    }
}
