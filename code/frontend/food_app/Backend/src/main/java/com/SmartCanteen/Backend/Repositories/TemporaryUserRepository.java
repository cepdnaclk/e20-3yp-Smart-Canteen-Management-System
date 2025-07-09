package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.TemporaryUser;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface TemporaryUserRepository extends JpaRepository<TemporaryUser, Long> {
    Optional<TemporaryUser> findByEmail(String email);
    boolean existsByEmail(String email);
}