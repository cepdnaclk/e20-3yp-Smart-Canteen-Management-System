package com.SmartCanteen.Backend.Entities;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@Entity
@Table(name = "admins")
public class Admin extends User {
    // Additional admin-specific fields if needed
}
