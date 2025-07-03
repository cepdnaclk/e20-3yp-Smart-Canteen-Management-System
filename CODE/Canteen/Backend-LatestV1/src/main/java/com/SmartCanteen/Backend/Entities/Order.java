//package com.SmartCanteen.Backend.Entities;
//
//import jakarta.persistence.*;
//import lombok.Data;
//import lombok.NoArgsConstructor;
//
//import java.math.BigDecimal;
//import java.time.LocalDateTime;
//import java.util.Map;
//
//@Data
//@NoArgsConstructor
//@Entity
//@Table(name = "orders")
//public class Order {
//
//    @Id
//    @GeneratedValue(strategy = GenerationType.IDENTITY)
//    private Long id;
//
//    @ManyToOne(optional = false)
//    @JoinColumn(name = "customer_id", referencedColumnName = "user_id")
//    private Customer customer;
//
//    // Map of MenuItem ID to quantity
//    @ElementCollection
//    @CollectionTable(name = "order_items", joinColumns = @JoinColumn(name = "order_id"))
//    @MapKeyColumn(name = "menu_item_id")
//    @Column(name = "quantity")
//    private Map<String, Integer> items;
//
//    private BigDecimal totalAmount;
//
//    @Enumerated(EnumType.STRING)
//    private OrderStatus status;
//
//    private LocalDateTime orderTime;
//
//    private String email;
//
//    @ManyToOne
//    @JoinColumn(name = "user_id") // Still uses ID internally
//    private User user;
//
//    private LocalDateTime scheduledTime; // nullable for immediate orders
//
//    /// ////
//    private boolean balanceDeducted = false;
//
//
//
//
//}


package com.SmartCanteen.Backend.Entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

@Data
@NoArgsConstructor
@Entity
@Table(name = "orders")
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "customer_id", referencedColumnName = "user_id")
    private Customer customer;

    // --- FIX: The map key is now correctly typed as Long ---
    @ElementCollection(fetch = FetchType.EAGER) // Eager fetch for easier processing
    @CollectionTable(name = "order_items", joinColumns = @JoinColumn(name = "order_id"))
    @MapKeyColumn(name = "menu_item_id")
    @Column(name = "quantity")
    private Map<Long, Integer> items;

    private BigDecimal totalAmount;

    @Enumerated(EnumType.STRING)
    private OrderStatus status;

    private LocalDateTime orderTime;

    // This field is redundant as we have the customer object. It can be removed for cleaner code,
    // but I will leave it for now to minimize breaking changes to your existing logic.
    private String email;

    private LocalDateTime scheduledTime;

    private boolean balanceDeducted = false;
}