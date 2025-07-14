package com.SmartCanteen.Backend.DTOs;

import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Data
public class MenuItemDTO {
    private Long id;
    @NotBlank(message = "Name is required")
    private String name;
    @NotNull(message = "Category ID is required")
    private Long categoryId;
    private String categoryName;
    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.0", inclusive = false, message = "Price must be positive")
    private BigDecimal price;
    private String imagePath;
    @NotNull(message = "Stock is required")
    @Min(value = 0, message = "Stock cannot be negative")
    private Integer stock;
    private Boolean isInTodayMenu;

    // Explicit getter/setter for proper JSON serialization
    public Boolean getIsInTodayMenu() {
        return isInTodayMenu;
    }

    public void setIsInTodayMenu(Boolean inTodayMenu) {
        isInTodayMenu = inTodayMenu;
    }
}
