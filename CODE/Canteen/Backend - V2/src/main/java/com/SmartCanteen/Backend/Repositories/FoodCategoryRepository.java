package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.FoodCategory;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FoodCategoryRepository extends JpaRepository<FoodCategory, Long> {
}
