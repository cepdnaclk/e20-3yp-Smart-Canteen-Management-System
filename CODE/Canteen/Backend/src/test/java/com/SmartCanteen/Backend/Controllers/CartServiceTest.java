package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.CartDTO;
import com.SmartCanteen.Backend.DTOs.CartItemDTO;
import com.SmartCanteen.Backend.Repositories.CartRepository;
import com.SmartCanteen.Backend.Services.CartService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
public class CartServiceTest {
    @Autowired
    private CartService cartService;
    @Autowired
    private CartRepository cartRepository;

    @Test
    void addItemToCart_ShouldAddItem() {
        Long userId = 1L;
        CartItemDTO item = new CartItemDTO(1L, 2);
        CartDTO cart = cartService.addItem(userId, item);
        assertThat(cart.getItems()).hasSize(1);
        assertThat(cart.getItems().get(0).getMenuItemId()).isEqualTo(1L);
    }
}
