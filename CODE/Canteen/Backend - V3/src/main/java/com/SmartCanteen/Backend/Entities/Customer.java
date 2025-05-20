package com.SmartCanteen.Backend.Entities;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@Entity
@Table(name = "customers")
public class Customer extends User {

    private BigDecimal creditBalance = BigDecimal.ZERO;

    // Additional customer-specific fields if needed
}
