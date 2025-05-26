import React from "react";
import NavBar from "../../components/NavBar/NavBar";
import './Menu.css';

const menuItems = [
  {
    id: 1,
    name: "Kottu Roti",
    description: "Chopped roti stir-fried with vegetables, eggs, and spices.",
    price: 8.99,
    image: "https://images.unsplash.com/photo-1600891964599-f61ba0e24092?auto=format&fit=crop&w=800&q=80"
  },
  {
    id: 2,
    name: "String Hoppers",
    description: "Steamed rice flour noodles served with sambol and curry.",
    price: 7.99,
    image: "https://images.unsplash.com/photo-1551218808-94e220e084d2?auto=format&fit=crop&w=800&q=80"
  },
  {
    id: 3,
    name: "Egg Hopper",
    description: "Bowl-shaped rice pancake with an egg cooked in the center.",
    price: 9.49,
    image: "https://images.unsplash.com/photo-1617191514667-5d5e3a4b3f5e?auto=format&fit=crop&w=800&q=80"
  },
  {
    id: 4,
    name: "Pol Roti",
    description: "Flatbread made with grated coconut, served with spicy sambol.",
    price: 5.99,
    image: "https://images.unsplash.com/photo-1617191514667-5d5e3a4b3f5e?auto=format&fit=crop&w=800&q=80"
  },
  {
    id: 5,
    name: "Kiribath",
    description: "Rice cooked in coconut milk, traditionally served for breakfast.",
    price: 6.49,
    image: "https://images.unsplash.com/photo-1568605114967-8130f3a36994?auto=format&fit=crop&w=800&q=80"
  },
  {
    id: 6,
    name: "Fish Ambul Thiyal",
    description: "Sour fish curry made with tamarind and spices.",
    price: 12.99,
    image: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80"
  }
];

function MenuItem({ item }) {
  const [imgSrc, setImgSrc] = React.useState(item.image);

  const handleError = () => {
    setImgSrc('/images/fallback-food.jpg'); // fallback image in public folder
  };

  return (
    <article className="menu-item-card">
      <img src={imgSrc} alt={item.name} onError={handleError} className="menu-item-image" />
      <h2>{item.name}</h2>
      <p>{item.description}</p>
      <p className="menu-item-price">${item.price.toFixed(2)}</p>
      <button className="order-button">Add to Order</button>
    </article>
  );
}

function Menu() {
  return (
    <div className="menu-container">
      <NavBar />
      <main>
        <h1>Choose Your Favourite Meals</h1>
        <section className="menu-items">
          {menuItems.map(item => (
            <MenuItem key={item.id} item={item} />
          ))}
        </section>
      </main>
    </div>
  );
}

export default Menu;
