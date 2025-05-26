import React, { useState, useEffect } from "react";
import './MyOrders.css';
import NavBar from "../../components/NavBar/NavBar";

function MyOrders() {
  const [orders, setOrders] = useState([]);

  useEffect(() => {
    const fetchedOrders = [
      {
        id: "ORD001",
        date: "2025-05-20",
        items: [
          { name: "Kottu Roti", quantity: 2, price: 8.99 },
          { name: "Egg Hopper", quantity: 1, price: 9.49 },
        ],
        total: 27.47,
        status: "Delivered",
      },
      {
        id: "ORD002",
        date: "2025-05-22",
        items: [
          { name: "String Hoppers", quantity: 3, price: 7.99 },
        ],
        total: 23.97,
        status: "In Progress",
      },
    ];

    setTimeout(() => {
      setOrders(fetchedOrders);
    }, 500);
  }, []);

  return (
    <div className="my-orders-container">
        <NavBar/>
      <h1 className="page-title">My Orders</h1>

      {orders.length === 0 ? (
        <p className="no-orders-msg">You have no past orders.</p>
      ) : (
        orders.map(order => (
          <div key={order.id} className="order-card">
            <h2 className="order-id">Order #{order.id}</h2>
            <p><strong>Date:</strong> {new Date(order.date).toLocaleDateString()}</p>
            <p>
              <strong>Status:</strong> 
              <span className={`order-status ${order.status === "Delivered" ? "delivered" : "in-progress"}`}>
                {order.status}
              </span>
            </p>

            <h3>Items:</h3>
            <ul className="order-items-list">
              {order.items.map((item, index) => (
                <li key={index}>
                  {item.quantity} × {item.name} @ LKR {item.price.toFixed(2)}
                </li>
              ))}
            </ul>

            <p className="order-total">Total: LKR {order.total.toFixed(2)}</p>
          </div>
        ))
      )}
    </div>
  );
}

export default MyOrders;
