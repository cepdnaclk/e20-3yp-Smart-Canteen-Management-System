import React, { useState } from "react";

function CartItemCard({ item, onRemove, onCheckout }) {
  const [imgSrc, setImgSrc] = useState(item.image || '/images/fallback-food.jpg');
  const [status, setStatus] = useState(null);

  const handleError = () => {
    setImgSrc('/images/fallback-food.jpg');
  };

  const handleCheckout = async () => {
    setStatus('processing');
    try {
      if (onCheckout) {
        await onCheckout(item);
      }
      setStatus('success');
      setTimeout(() => setStatus(null), 2000);
    } catch (error) {
      setStatus('error');
    }
  };

  const handleRemoveClick = () => {
    if (onRemove) {
      onRemove(item.id);
    }
  };

    const showTotalPrice = (price, quantity) => {
  return price * quantity;
};


  return (
    <div style={styles.card}>
      <img
        src={imgSrc}
        alt={item.name}
        onError={handleError}
        style={styles.image}
      />
      <div style={styles.details}>
        <h3 style={styles.name}>{item.name}</h3>
        <p style={styles.text}>Quantity: {item.quantity}</p>
        <p style={styles.text}>
  Total Price: Rs {showTotalPrice(Number(item.price) || 0, Number(item.quantity) || 0).toFixed(2)}
</p>

      </div>
      <div style={styles.buttons}>
        <button
          onClick={handleCheckout}
          disabled={status === 'processing'}
          style={{ ...styles.button, ...styles.checkoutButton }}
        >
          {status === 'processing' ? 'Processing...' : 'Checkout'}
        </button>
        <button
          onClick={handleRemoveClick}
          style={{ ...styles.button, ...styles.removeButton }}
          aria-label={`Remove ${item.name}`}
        >
          &times;
        </button>
      </div>
      {status === 'success' && <p style={styles.successMsg}>Checkout successful!</p>}
      {status === 'error' && <p style={styles.errorMsg}>Checkout failed. Try again.</p>}
    </div>
  );
}

const styles = {
  card: {
    display: 'flex',
    alignItems: 'center',
    border: '1px solid #ddd',
    borderRadius: 10,
    padding: 16,
    marginBottom: 16,
    backgroundColor: '#fafafa',
    boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
    position: 'relative',
  },
  image: {
    width: 100,
    height: 80,
    objectFit: 'cover',
    borderRadius: 8,
    marginRight: 20,
    flexShrink: 0,
  },
  details: {
    flexGrow: 1,
  },
  name: {
    fontSize: 18,
    fontWeight: 600,
    margin: '0 0 8px 0',
    color: '#333',
  },
  text: {
    margin: '4px 0',
    fontSize: 14,
    color: '#555',
  },
  buttons: {
    display: 'flex',
    flexDirection: 'column',
    gap: 8,
  },
  button: {
    border: 'none',
    borderRadius: 6,
    padding: '8px 14px',
    fontWeight: 600,
    cursor: 'pointer',
    fontSize: 14,
  },
  checkoutButton: {
    backgroundColor: '#007bff',
    color: 'white',
  },
  removeButton: {
    backgroundColor: '#dc3545',
    color: 'white',
    fontSize: 20,
    lineHeight: 1,
    padding: '4px 10px',
  },
  successMsg: {
    position: 'absolute',
    bottom: 8,
    right: 16,
    color: 'green',
    fontWeight: 600,
    fontSize: 14,
  },
  errorMsg: {
    position: 'absolute',
    bottom: 8,
    right: 16,
    color: 'red',
    fontWeight: 600,
    fontSize: 14,
  },
};

export default CartItemCard;
