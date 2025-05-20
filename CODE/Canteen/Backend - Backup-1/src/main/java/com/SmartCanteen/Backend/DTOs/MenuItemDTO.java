package com.SmartCanteen.Backend.DTOs;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class MenuItemDTO {
    private Long id;
    private String name;
    private Long categoryId;      // use this to link to the category
    private String categoryName;  // optional: for display purposes
    private BigDecimal price;
    private Integer stock;
}

