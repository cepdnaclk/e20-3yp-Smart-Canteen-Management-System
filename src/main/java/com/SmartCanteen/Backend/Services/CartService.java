//package com.SmartCanteen.Backend.Services;
//
//import com.SmartCanteen.Backend.DTOs.CartDTO;
//import com.SmartCanteen.Backend.DTOs.CartItemDTO;
//import com.SmartCanteen.Backend.Entities.Cart;
//import com.SmartCanteen.Backend.Entities.CartItem;
//import com.SmartCanteen.Backend.Repositories.CartRepository;
//import org.springframework.stereotype.Service;
//
//import java.util.ArrayList;
//import java.util.List;
//import java.util.stream.Collectors;
//
//@Service
//public class CartService {
//    private final CartRepository cartRepository;
//
//    public CartService(CartRepository cartRepository) {
//        this.cartRepository = cartRepository;
//    }
//
//    private List<CartItemDTO> mapCartItemsToDTO(List<CartItem> cartItems) {
//        return cartItems.stream()
//                .map(item -> new CartItemDTO(item.getMenuItemId(), item.getQuantity()))
//                .collect(Collectors.toList());
//    }
//
//    public CartDTO getCart(Long userId) {
//        Cart cart = cartRepository.findByUserId(userId)
//                .orElseGet(() -> new Cart(userId, new ArrayList<>()));
//        CartDTO cartDTO = new CartDTO();
//        cartDTO.setUserId(cart.getUserId());
//        cartDTO.setItems(mapCartItemsToDTO(cart.getItems()));
//        return cartDTO;
//    }
//
//    public CartDTO addItem(Long userId, CartItemDTO item) {
//        Cart cart = cartRepository.findByUserId(userId)
//                .orElseGet(() -> new Cart(userId, new ArrayList<>()));
//        cart.getItems().stream()
//                .filter(i -> i.getMenuItemId().equals(item.getMenuItemId()))
//                .findFirst()
//                .ifPresentOrElse(
//                        i -> i.setQuantity(i.getQuantity() + item.getQuantity()),
//                        () -> cart.getItems().add(new CartItem(item.getMenuItemId(), item.getQuantity()))
//                );
//        cartRepository.save(cart);
//        CartDTO cartDTO = new CartDTO();
//        cartDTO.setUserId(cart.getUserId());
//        cartDTO.setItems(mapCartItemsToDTO(cart.getItems()));
//        return cartDTO;
//    }
//
//    public CartDTO removeItem(Long userId, CartItemDTO item) {
//        Cart cart = cartRepository.findByUserId(userId)
//                .orElseThrow(() -> new RuntimeException("Cart not found"));
//        cart.getItems().removeIf(i -> i.getMenuItemId().equals(item.getMenuItemId()));
//        cartRepository.save(cart);
//        CartDTO cartDTO = new CartDTO();
//        cartDTO.setUserId(cart.getUserId());
//        cartDTO.setItems(mapCartItemsToDTO(cart.getItems()));
//        return cartDTO;
//    }
//
//    public CartDTO clearCart(Long userId) {
//        Cart cart = cartRepository.findByUserId(userId)
//                .orElseThrow(() -> new RuntimeException("Cart not found"));
//        cart.getItems().clear();
//        cartRepository.save(cart);
//        CartDTO cartDTO = new CartDTO();
//        cartDTO.setUserId(cart.getUserId());
//        cartDTO.setItems(mapCartItemsToDTO(cart.getItems()));
//        return cartDTO;
//    }
//}


package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.CartDTO;
import com.SmartCanteen.Backend.DTOs.CartItemDTO;
import com.SmartCanteen.Backend.Entities.Cart;
import com.SmartCanteen.Backend.Entities.CartItem;
import com.SmartCanteen.Backend.Entities.MenuItem;
import com.SmartCanteen.Backend.Repositories.CartRepository;
import com.SmartCanteen.Backend.Repositories.MenuItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CartService {
    private final CartRepository cartRepository;
    private final MenuItemRepository menuItemRepository;

    public CartDTO getCart(Long userId) {
        Cart cart = findOrCreateCartByUserId(userId);
        return mapCartToDTO(cart);
    }

    @Transactional
    public CartDTO addItem(Long userId, CartItemDTO itemToAdd) {
        MenuItem menuItem = menuItemRepository.findById(itemToAdd.getMenuItemId())
                .orElseThrow(() -> new RuntimeException("Menu item not found"));

        if (menuItem.getStock() < itemToAdd.getQuantity()) {
            throw new RuntimeException("Insufficient stock for " + menuItem.getName() + ". Only " + menuItem.getStock() + " available.");
        }

        Cart cart = findOrCreateCartByUserId(userId);

        cart.getItems().stream()
                .filter(i -> i.getMenuItemId().equals(itemToAdd.getMenuItemId()))
                .findFirst()
                .ifPresentOrElse(
                        existingItem -> {
                            int newQuantity = existingItem.getQuantity() + itemToAdd.getQuantity();
                            if (menuItem.getStock() < newQuantity) {
                                throw new RuntimeException("Cannot add " + itemToAdd.getQuantity() + " more of " + menuItem.getName() + ". Total would exceed stock.");
                            }
                            existingItem.setQuantity(newQuantity);
                        },
                        () -> cart.getItems().add(new CartItem(itemToAdd.getMenuItemId(), itemToAdd.getQuantity()))
                );

        Cart savedCart = cartRepository.save(cart);
        return mapCartToDTO(savedCart);
    }

    @Transactional
    public CartDTO removeItem(Long userId, CartItemDTO itemToRemove) {
        Cart cart = findOrCreateCartByUserId(userId);
        cart.getItems().removeIf(i -> i.getMenuItemId().equals(itemToRemove.getMenuItemId()));
        cartRepository.save(cart);
        return mapCartToDTO(cart);
    }

    @Transactional
    public CartDTO clearCart(Long userId) {
        cartRepository.findByUserId(userId).ifPresent(cartRepository::delete);

        CartDTO emptyCart = new CartDTO();
        emptyCart.setUserId(userId);
        emptyCart.setItems(new ArrayList<>());
        return emptyCart;
    }

    // --- FIX: The missing private helper method is now included ---
    private Cart findOrCreateCartByUserId(Long userId) {
        return cartRepository.findByUserId(userId)
                .orElseGet(() -> {
                    Cart newCart = new Cart(userId, new ArrayList<>());
                    return cartRepository.save(newCart);
                });
    }

    private CartDTO mapCartToDTO(Cart cart) {
        CartDTO cartDTO = new CartDTO();
        cartDTO.setUserId(cart.getUserId());
        cartDTO.setItems(mapCartItemsToDTO(cart.getItems()));
        return cartDTO;
    }

    private List<CartItemDTO> mapCartItemsToDTO(List<CartItem> cartItems) {
        return cartItems.stream()
                .map(item -> new CartItemDTO(item.getMenuItemId(), item.getQuantity()))
                .collect(Collectors.toList());
    }
}