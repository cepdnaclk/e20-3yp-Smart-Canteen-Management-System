package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.Merchant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MerchantRepository extends JpaRepository<Merchant, Long> {
    Optional<Merchant> findByUsername(String username);

    Optional<Merchant> findByEmail(String email);  // Add this line
}
