// src/components/PopularItems/PopularItems.jsx
import './PopularItems.css';


function PopularItems() {
  const menuItems = [
    {
      id: 1,
      name: 'Kottu Roti',
      description: 'Fresh mixed greens with grilled chicken, avocado, and balsamic dressing',
      price: 8.99,
      image: 'https://cdn.pixabay.com/photo/2017/06/02/18/24/kottu-roti-2369550_1280.jpg',
      category: 'Healthy',
      rating: 4.8
    },
    {
      id: 2,
      name: 'String Hoppers (Indi Appa)',
      description: 'Angus beef patty with cheddar cheese, lettuce, tomato, and special sauce',
      price: 7.99,
      image: 'https://cdn.pixabay.com/photo/2017/06/03/16/15/indian-food-2369930_1280.jpg',
      category: 'Burgers',
      rating: 4.6
    },
    {
      id: 3,
      name: 'Pol Roti',
      description: 'Hand-tossed pizza with fresh mozzarella, tomatoes, and basil',
      price: 10.99,
      image: 'https://cdn.pixabay.com/photo/2018/06/07/19/12/roti-3469166_1280.jpg',
      category: 'Pizza',
      rating: 4.7
    },
    {
      id: 4,
      name: 'Egg Hopper',
      description: 'Fresh seasonal vegetables stir-fried with tofu and teriyaki sauce',
      price: 9.99,
      image: 'https://cdn.pixabay.com/photo/2020/04/23/03/19/hopper-5089807_1280.jpg',
      category: 'Vegetarian',
      rating: 4.5
    },
    {
      id: 5,
      name: 'Kiribath (Milk Rice)',
      description: 'Warm chocolate brownie topped with vanilla ice cream and hot fudge',
      price: 5.99,
      image: 'https://cdn.pixabay.com/photo/2017/06/28/22/57/kiribath-2454011_1280.jpg',
      category: 'Desserts',
      rating: 4.9
    },
    {
      id: 6,
      name: 'Fish Ambul Thiyal (Sour Fish Curry)',
      description: 'Sour fish curry made with fresh fish, spices, and a tangy marinade.',
      price: 12.99,
      image: 'https://cdn.pixabay.com/photo/2018/02/07/15/16/fish-curry-3139296_1280.jpg',
      category: 'Healthy',
      rating: 4.7
    }
  ];

  return (
    <section id="popular-items" className="popular-items">
      <div className="container">
        <h2 className="section-title">Most Popular Items</h2>
        <div className="menu-filter">
          <button className="filter-btn active">All</button>
          <button className="filter-btn">Healthy</button>
          <button className="filter-btn">Burgers</button>
          <button className="filter-btn">Pizza</button>
          <button className="filter-btn">Vegetarian</button>
          <button className="filter-btn">Desserts</button>
        </div>
        <div className="menu-grid">
          {menuItems.map((item) => (
            <div className="menu-card" key={item.id}>
              <div className="menu-image">
                <img src={item.image} alt={item.name} />
                <span className="menu-category">{item.category}</span>
              </div>
              <div className="menu-info">
                <div className="menu-header">
                  <h3>{item.name}</h3>
                  <span className="menu-price">${item.price.toFixed(2)}</span>
                </div>
                <p className="menu-description">{item.description}</p>
                <div className="menu-footer">
                  <div className="menu-rating">
                    <i className="fas fa-star"></i>
                    <span>{item.rating}</span>
                  </div>
                  <button className="add-to-cart-btn">
                    <i className="fas fa-plus"></i> Add to Order
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
        <div className="text-center mt-4">
          <a href="/menu" className="btn btn-outline">View Full Menu</a>
        </div>
      </div>
    </section>
  );
}

export default PopularItems;