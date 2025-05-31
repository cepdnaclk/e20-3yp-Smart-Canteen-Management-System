// src/pages/Menu/Menu.jsx
import React, { useState, useEffect } from "react";
import NavBar from "../../components/NavBar/NavBar";
import FoodItemCard from "../../components/FoodItemCard/FoodItemCard"; 
import './Menu.css';
import { loadMenu, addToCart } from "../../services/Api.jsx";

function Menu() {
  const [menuItems, setMenuItems] = useState([]);
  const [menuLoading, setMenuLoading] = useState(true);
  const [menuError, setMenuError] = useState(null);

  useEffect(() => {
    async function fetchMenuData() {
      try {
        const data = await loadMenu();
        setMenuItems(data);
      } catch (err) {
        setMenuError(err.message);
      } finally {
        setMenuLoading(false);
      }
    }
    fetchMenuData();
  }, []);

  return (
    <div className="menu-container">
      <NavBar />
      <main>
        <h1>Choose Your Favourite Meals</h1>
        {menuLoading && <p>Loading menu...</p>}
        {menuError && <p className="error">Error: {menuError}</p>}
        {!menuLoading && !menuError && (
          <section className="menu-items">
            {menuItems.map(item => (
              <FoodItemCard key={item.id} item={item} addToCart={addToCart} />
            ))}
          </section>
        )}
      </main>
    </div>
  );
}

export default Menu;
