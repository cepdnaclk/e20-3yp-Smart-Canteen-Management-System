package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.Role;
import com.SmartCanteen.Backend.Entities.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
    Optional<User> findByCardID(String cardID);

    // Add this method to UserRepository.java
    long countByRole(Role role);
}
