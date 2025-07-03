package com.SmartCanteen.Backend.Controllers;

import lombok.Data;

import java.math.BigDecimal;

// DTO for MenuItem creation
@Data
public class MenuItemRequest {
    private String name;
    private BigDecimal price;
    private Integer stock;
    private Long categoryId;
}
