package com.SmartCanteen.Backend.Entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@Entity
@Table(name = "merchants")
@PrimaryKeyJoinColumn(name = "user_id")
public class Merchant extends User {
    private String canteenName;
}
