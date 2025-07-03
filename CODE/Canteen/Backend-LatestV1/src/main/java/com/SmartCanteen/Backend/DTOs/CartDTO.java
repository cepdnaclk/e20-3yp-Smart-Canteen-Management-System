package com.SmartCanteen.Backend.DTOs;

import lombok.Data;
import java.util.List;

@Data
public class CartDTO {
    private Long userId;
    private List<CartItemDTO> items; // <-- Must be List<CartItemDTO>
}