//package com.SmartCanteen.Backend.Entities;
//
//import jakarta.persistence.*;
//import lombok.Data;
//import lombok.NoArgsConstructor;
//
//import java.math.BigDecimal;
//import java.util.List;
//
//@Data
//@NoArgsConstructor
//@Entity
//@Table(name = "customers")
//@PrimaryKeyJoinColumn(name = "user_id")
//public class Customer extends User {
//
//    private BigDecimal creditBalance = BigDecimal.ZERO;
//
//    @OneToMany(mappedBy = "customer", cascade = CascadeType.ALL)
//    private List<Order> orders;
//
//    @OneToMany(mappedBy = "recipient")
//    private List<Notification> notifications;
//    // Additional customer-specific fields if needed
//}


package com.SmartCanteen.Backend.Entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@EqualsAndHashCode(callSuper = true)
@Data
@NoArgsConstructor
@Entity
@Table(name = "customers")
@PrimaryKeyJoinColumn(name = "user_id")
public class Customer extends User {

    private BigDecimal creditBalance = BigDecimal.ZERO;

    // New field for profile picture
    private String profileImagePath;

    @OneToMany(mappedBy = "customer", cascade = CascadeType.ALL)
    private List<Order> orders;

    @OneToMany(mappedBy = "recipient")
    private List<Notification> notifications;
}