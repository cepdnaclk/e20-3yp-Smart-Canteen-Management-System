
package com.SmartCanteen.Backend.Entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@Entity
@Table(name = "merchants")
@PrimaryKeyJoinColumn(name = "customer_id")
public class Merchant extends Customer {


    private String canteenName;
}
