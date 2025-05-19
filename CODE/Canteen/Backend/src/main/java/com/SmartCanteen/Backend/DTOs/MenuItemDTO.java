package com.SmartCanteen.Backend.DTOs;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class MenuItemDTO {
    private Long id;
    private String name;
    private String category;
    private BigDecimal price;
    private Integer stock;
}
