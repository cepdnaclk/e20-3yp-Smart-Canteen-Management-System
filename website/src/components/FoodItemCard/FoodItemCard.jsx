
import React, { useState } from "react";
import './FoodItemCard.css'; 

function FoodItemCard({ item, addToCart }) {
  const [imgSrc, setImgSrc] = useState(item.image || '/images/fallback-food.jpg');
  const [status, setStatus] = useState(null);

  const handleAddToCart = async () => {
    setStatus('loading');

    // Debug: Check if token exists
    const token = localStorage.getItem('userToken');
    console.log("Token exists:", !!token);
    console.log("Token value:", token ? token.substring(0, 50) + "..." : "No token");
    console.log("item id is: ", item.id);

    try {
      await addToCart({
        menuItemId: item.id, quantity: 1, name: item.name, price: item.price
      });
      setStatus('success');
      setTimeout(() => setStatus(null), 2000);
    } catch (err) {
      setStatus('error');
    }
  };

  const handleError = () => {
    setImgSrc('/images/fallback-food.jpg');
  };

 

  return (
    <article className="menu-item-card">
      <img
        src={imgSrc}
        alt={item.name}
        onError={handleError}
        className="menu-item-image"
      />
      <h2>{item.name}</h2>
      <p>{item.description}</p>
      <p className="menu-item-price">Rs {Number(item.price).toFixed(2)}</p>
      <button
        className="order-button"
        onClick={handleAddToCart}
        disabled={status === 'loading'}
      >
        {status === 'loading' ? 'Adding...' : 'Add to Order'}
      </button>
      {status === 'success' && <span className="success-msg">Added!</span>}
      {status === 'error' && <span className="error-msg">Failed to add</span>}
    </article>
  );
}

export default FoodItemCard;
