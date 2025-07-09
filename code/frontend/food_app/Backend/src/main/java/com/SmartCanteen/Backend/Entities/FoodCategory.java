package com.SmartCanteen.Backend.Entities;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "food_categories")
@Data
public class FoodCategory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    private String description;
}
