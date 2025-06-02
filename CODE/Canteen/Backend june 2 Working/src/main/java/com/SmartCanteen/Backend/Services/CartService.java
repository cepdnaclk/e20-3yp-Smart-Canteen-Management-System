package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.CartDTO;
import com.SmartCanteen.Backend.DTOs.CartItemDTO;
import com.SmartCanteen.Backend.Entities.Cart;
import com.SmartCanteen.Backend.Entities.CartItem;
import com.SmartCanteen.Backend.Repositories.CartRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class CartService {
    private final CartRepository cartRepository;

    public CartService(CartRepository cartRepository) {
        this.cartRepository = cartRepository;
    }

    private List<CartItemDTO> mapCartItemsToDTO(List<CartItem> cartItems) {
        return cartItems.stream()
                .map(item -> new CartItemDTO(item.getMenuItemId(), item.getQuantity()))
                .collect(Collectors.toList());
    }

    public CartDTO getCart(Long userId) {
        Cart cart = cartRepository.findByUserId(userId)
                .orElseGet(() -> new Cart(userId, new ArrayList<>()));
        CartDTO cartDTO = new CartDTO();
        cartDTO.setUserId(cart.getUserId());
        cartDTO.setItems(mapCartItemsToDTO(cart.getItems()));
        return cartDTO;
    }

    public CartDTO addItem(Long userId, CartItemDTO item) {
        Cart cart = cartRepository.findByUserId(userId)
                .orElseGet(() -> new Cart(userId, new ArrayList<>()));
        cart.getItems().stream()
                .filter(i -> i.getMenuItemId().equals(item.getMenuItemId()))
                .findFirst()
                .ifPresentOrElse(
                        i -> i.setQuantity(i.getQuantity() + item.getQuantity()),
                        () -> cart.getItems().add(new CartItem(item.getMenuItemId(), item.getQuantity()))
                );
        cartRepository.save(cart);
        CartDTO cartDTO = new CartDTO();
        cartDTO.setUserId(cart.getUserId());
        cartDTO.setItems(mapCartItemsToDTO(cart.getItems()));
        return cartDTO;
    }

    public CartDTO removeItem(Long userId, CartItemDTO item) {
        Cart cart = cartRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Cart not found"));
        cart.getItems().removeIf(i -> i.getMenuItemId().equals(item.getMenuItemId()));
        cartRepository.save(cart);
        CartDTO cartDTO = new CartDTO();
        cartDTO.setUserId(cart.getUserId());
        cartDTO.setItems(mapCartItemsToDTO(cart.getItems()));
        return cartDTO;
    }

    public CartDTO clearCart(Long userId) {
        Cart cart = cartRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Cart not found"));
        cart.getItems().clear();
        cartRepository.save(cart);
        CartDTO cartDTO = new CartDTO();
        cartDTO.setUserId(cart.getUserId());
        cartDTO.setItems(mapCartItemsToDTO(cart.getItems()));
        return cartDTO;
    }
}
