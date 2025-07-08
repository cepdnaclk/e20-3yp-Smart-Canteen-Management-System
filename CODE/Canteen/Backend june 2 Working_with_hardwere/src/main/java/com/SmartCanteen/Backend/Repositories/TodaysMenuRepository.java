package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.TodaysMenuItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface TodaysMenuRepository extends JpaRepository<TodaysMenuItem, Long> {
    List<TodaysMenuItem> findByDate(LocalDate date);
    void deleteByDate(LocalDate date);
    boolean existsByMenuItemIdAndDate(Long menuItemId, LocalDate date);

}
