//package com.SmartCanteen.Backend.Repositories;
//
//import com.SmartCanteen.Backend.Entities.MenuItem;
//import org.springframework.data.jpa.repository.JpaRepository;
//
//import java.util.List;
//
//public interface MenuItemRepository extends JpaRepository<MenuItem, Long> {
//    List<MenuItem> findByCategoryId(Long categoryId);
//}



package com.SmartCanteen.Backend.Repositories;

import com.SmartCanteen.Backend.Entities.MenuItem;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface MenuItemRepository extends JpaRepository<MenuItem, Long> {
    List<MenuItem> findByCategoryId(Long categoryId);

    // --- NEW: For StockAlertService ---
    List<MenuItem> findByStockLessThan(Integer stockLevel);

    // --- NEW: To get all items for a specific merchant ---
    List<MenuItem> findByCategory_Merchant_Id(Long merchantId);
}