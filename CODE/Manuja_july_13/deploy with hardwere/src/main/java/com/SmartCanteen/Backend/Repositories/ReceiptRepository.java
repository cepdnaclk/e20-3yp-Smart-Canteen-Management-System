package com.SmartCanteen.Backend.Repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import com.SmartCanteen.Backend.Entities.Receipt;

public interface ReceiptRepository extends JpaRepository<Receipt, Long> {
    // No extra methods needed for save()
}
