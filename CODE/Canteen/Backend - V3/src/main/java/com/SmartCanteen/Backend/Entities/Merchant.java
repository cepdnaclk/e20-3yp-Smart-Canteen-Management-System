package com.SmartCanteen.Backend.Entities;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@Entity
@Table(name = "merchants")
public class Merchant extends User {
    // Additional merchant-specific fields like shopName can be added here
}
