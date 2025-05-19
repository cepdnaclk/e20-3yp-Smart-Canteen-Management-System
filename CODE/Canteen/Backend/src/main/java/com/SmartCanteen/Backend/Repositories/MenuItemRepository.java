package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.MenuItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MenuItemRepository extends JpaRepository<MenuItem, Long> {
    // You can add custom query methods here if needed
}
