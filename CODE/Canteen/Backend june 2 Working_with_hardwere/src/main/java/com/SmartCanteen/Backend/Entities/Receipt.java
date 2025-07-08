package com.SmartCanteen.Backend.Entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

@Data
@Entity
public class Receipt {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    private Order order;

    private String customerEmail;

    @ElementCollection
    @CollectionTable(name = "receipt_items", joinColumns = @JoinColumn(name = "receipt_id"))
    @MapKeyColumn(name = "item_name")
    @Column(name = "quantity")
    private Map<String, Integer> items;

    private BigDecimal totalAmount;
    private LocalDateTime generatedAt;

    @Setter
    @Getter
    private LocalDateTime generatedDate;

}
