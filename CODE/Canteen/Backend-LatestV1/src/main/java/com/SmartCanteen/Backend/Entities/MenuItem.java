//package com.SmartCanteen.Backend.Entities;
//
//import com.fasterxml.jackson.annotation.JsonBackReference;
//import jakarta.persistence.*;
//import lombok.Data;
//
//import java.math.BigDecimal;
//
//@Entity
//@Data
//@Table(name = "menu_items")
//public class MenuItem {
//
//    @Id
//    @GeneratedValue(strategy = GenerationType.IDENTITY)
//    private Long id;
//
//    @Column(nullable = false)
//    private String name;
//
//
//    @Column(nullable = false)
//    private BigDecimal price;
//
//    @Column(nullable = false)
//    private Integer stock;
//
//    @Column
//    private String imagePath;
//
//    @Version
//    private Integer version;
//
//    @ManyToOne
//    @JoinColumn(name = "category_id")
//    @JsonBackReference
//    private FoodCategory category;
//}


package com.SmartCanteen.Backend.Entities;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.Data;

import java.math.BigDecimal;

@Entity
@Data
@Table(name = "menu_items")
public class MenuItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private BigDecimal price;

    // --- NEW: Cost price for profit calculation ---
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal costPrice;

    @Column(nullable = false)
    private Integer stock;

    // --- Path for the food item's image ---
    @Column
    private String imagePath;

    @Version
    private Integer version;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    @JsonBackReference
    private FoodCategory category;
}