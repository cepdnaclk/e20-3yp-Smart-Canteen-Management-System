package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.FoodCategory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface FoodCategoryRepository extends JpaRepository<FoodCategory, Long> {
    boolean existsByName(String name);
    Optional<FoodCategory> findByName(String name);
}
