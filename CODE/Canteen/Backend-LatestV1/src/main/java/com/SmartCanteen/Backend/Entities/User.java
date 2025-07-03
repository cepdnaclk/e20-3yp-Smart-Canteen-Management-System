//package com.SmartCanteen.Backend.Entities;
//
//import jakarta.persistence.*;
//import lombok.Data;
//import lombok.NoArgsConstructor;
//
//@Data
//@NoArgsConstructor
//@Inheritance(strategy = InheritanceType.JOINED)
//@Entity
//@Table(name = "users")
//public abstract class User {
//
//    @Id
//    @GeneratedValue(strategy = GenerationType.IDENTITY)
//    private Long id;
//
//    @Column(unique = true, nullable = false, updatable = true)
//    private String username;
//
//    @Column(nullable = false)
//    private String password; // hashed
//
//    @Column(unique = true, nullable = false)
//    private String email;
//
//    private String fullName;
//
//    private String cardID;
//
//    private String fingerprintID;
//
//    @Enumerated(EnumType.STRING)
//    private Role role;
//}

package com.SmartCanteen.Backend.Entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@Inheritance(strategy = InheritanceType.JOINED)
@Entity
@Table(name = "users")
public abstract class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, updatable = true)
    private String username;

    @Column(nullable = false)
    private String password; // hashed

    @Column(unique = true, nullable = false)
    private String email;

    private String fullName;
    private String cardID;
    private String fingerprintID;

    @Enumerated(EnumType.STRING)
    private Role role;

    // --- NEW: For soft-deleting users ---
    @Column(nullable = false)
    private boolean active = true;
}