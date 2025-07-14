package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.Notification;
import com.SmartCanteen.Backend.Entities.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NotificationRepository extends JpaRepository<Notification, Long> {
    Page<Notification> findByRecipientOrderByTimestampDesc(User recipient, Pageable pageable);
}
