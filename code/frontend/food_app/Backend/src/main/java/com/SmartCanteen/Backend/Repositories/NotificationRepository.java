package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.Notification;
import com.SmartCanteen.Backend.Entities.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByRecipientOrderByTimestampDesc(User recipient);
}
