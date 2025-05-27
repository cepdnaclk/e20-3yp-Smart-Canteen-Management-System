package com.SmartCanteen.Backend.Entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;


@Entity
@Data
public class ScheduledOrder {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private Long userId;
    private LocalDateTime scheduledTime;
    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CartItem> items;
    private boolean processed = false;
}