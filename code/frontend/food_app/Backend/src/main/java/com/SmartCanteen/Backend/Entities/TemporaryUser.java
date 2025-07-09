//package com.SmartCanteen.Backend.Entities;
//
//import jakarta.persistence.*;
//import lombok.Data;
//
//import java.math.BigDecimal;
//
//@Entity
//@Table(name = "temporary_users")
//@Data
//public class TemporaryUser {
//    @Id
//    @GeneratedValue(strategy = GenerationType.IDENTITY)
//    private Long id;
//
//    @Column(nullable = false, unique = true)
//    private String email;
//
//    @Column(nullable = false)
//    private String password;
//
//    @Column(nullable = false)
//    private String username;
//
//    @Column
//    private String fullName;
//
//    @Column
//    private String cardID;
//
//    @Column
//    private String fingerprintID;
//
//    @Column
//    private BigDecimal creditBalance;
//
//    @Column
//    private String canteenName;
//
//    @Enumerated(EnumType.STRING)
//    @Column(nullable = false)
//    private Role role;
//}

package com.SmartCanteen.Backend.Entities;

import jakarta.persistence.*;
import lombok.Data;

import java.math.BigDecimal;

@Entity
@Table(name = "temporary_users")
@Data
public class TemporaryUser {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String username;

    private String fullName;
    private String cardID;
    private String fingerprintID;
    private BigDecimal creditBalance;
    private String canteenName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;
}
