package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.MenuItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MenuItemRepository extends JpaRepository<MenuItem, Long> {
    List<MenuItem> findByCategoryId(Long categoryId);
}
