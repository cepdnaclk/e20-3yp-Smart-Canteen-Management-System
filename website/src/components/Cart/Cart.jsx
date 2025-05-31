import React, { useEffect, useState } from "react";
import CartItemCard from "../../components/CartItemCard/CartItemCard"; 
import { getCart, removeItemFromCart } from "../../services/Api";
import NavBar from "../NavBar/NavBar";
import './Cart.css';

function CartPage() {
  const [cartItems, setCartItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    async function fetchCart() {
      try {
        setLoading(true);
        const data = await getCart();
        setCartItems(data.items || []);
      } catch (err) {
        setError(err.message || "Failed to load cart");
      } finally {
        setLoading(false);
      }
    }
    fetchCart();
  }, []);

  const handleRemove = async (itemId) => {
      console.log("Removing item with id:", itemId);
    try {
      await removeItemFromCart(itemId);
      setCartItems(prevItems => prevItems.filter(item => item.id !== itemId));
      console.log("Item removed successfully");
    } catch (error) {
      console.error("Failed to remove item from cart:", error);
      alert("Failed to remove item from cart. Please try again.");
    }
  };

/*
  useEffect(() => {
  console.log("Cart Items:", cartItems);
}, [cartItems]);
*/

  

  const handleCheckout = () => {
    alert("Checkout clicked! Implement checkout flow.");
  };

  if (loading) return <p>Loading cart...</p>;
  if (error) return <p className="error">Error: {error}</p>;

  return (
    <>
    <NavBar/>
    <div className="sc-cart-container">
      <h2 className="sc-cart-title">Your Shopping Cart</h2>
      {cartItems.length === 0 ? (
        <p className="sc-cart-empty">Your cart is empty.</p>
      ) : (
        <>
          <ul className="sc-cart-items-list">
            {cartItems.map(item => (
              <li key={item.menuItemId}>
                <CartItemCard 
                  item={item} 
                  onRemove={() => handleRemove(item.menuItemId)} 
                />
              </li>
            ))}
          </ul>
          <button 
            className="sc-cart-checkout-btn" 
            onClick={handleCheckout} 
            disabled={cartItems.length === 0}
          >
            Proceed to Checkout
          </button>
        </>
      )}
    </div>
    </>
  );
}

export default CartPage;
