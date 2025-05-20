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

    @ManyToOne(fetch = FetchType.LAZY)
    private Customer customer;

    @ManyToOne(fetch = FetchType.LAZY)
    private Merchant merchant;

    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    private RequestStatus status;

    private LocalDateTime requestTime;

    private LocalDateTime responseTime;
}
