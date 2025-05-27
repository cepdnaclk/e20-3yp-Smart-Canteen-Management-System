package com.SmartCanteen.Backend.Entities;

import com.SmartCanteen.Backend.Entities.CartItem;
import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.ArrayList;
import java.util.List;


@Data
@NoArgsConstructor
@Entity
public class Cart {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private Long userId;
    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CartItem> items = new ArrayList<>();

    public Cart(Long userId, List<CartItem> items) {
        this.userId = userId;
        this.items = items;
    }
}
