package com.SmartCanteen.Backend.DTOs;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class CartItemDTO {
    private Long menuItemId;
    private int quantity;
}
