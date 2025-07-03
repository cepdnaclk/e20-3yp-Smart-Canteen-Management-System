package com.SmartCanteen.Backend.Entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Data
@NoArgsConstructor
public class Message {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "sender_id", nullable = false)
    private User sender;

    @ManyToOne
    @JoinColumn(name = "recipient_id", nullable = false)
    private User recipient;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    private LocalDateTime timestamp;

    private boolean isRead = false;

    @PrePersist
    protected void onCreate() {
        timestamp = LocalDateTime.now();
    }
}