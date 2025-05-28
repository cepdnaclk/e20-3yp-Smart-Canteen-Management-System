package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.Admin;
import com.SmartCanteen.Backend.Entities.Merchant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.BitSet;
import java.util.Optional;

public interface AdminRepository extends JpaRepository<Admin, Long> {
    Optional<Admin> findByEmail(String username);


}
