import React, { useState, useEffect } from "react";
import NavBar from "../../components/NavBar/NavBar.jsx";
import "./Home.css";
import useNotifications, { fetchUser } from "../../services/Api.jsx";

function Home() {
  const [user, setUser] = useState(null);
  const [balance, setBalance] = useState(null);
  const { notifications, loading, error } = useNotifications();

   const [menu, setMenu] = useState([]);
  const [menuLoading, setMenuLoading] = useState(true);
  const [menuError, setMenuError] = useState(null);

   useEffect(() => {
  async function fetchMenuData() {
    try {
      const data = await loadMenu();
      setMenu(data);
    } catch (err) {
      setMenuError(err.message);
    } finally {
      setMenuLoading(false);
    }
  }
  fetchMenuData();
}, []);



  useEffect(() => {
    async function loadUserData() {
      try {
        const { username, balance } = await fetchUser();
        setUser(username);
        setBalance(balance);
      } catch (err) {
        console.error("Failed to fetch user data:", err);
      }
    }
    loadUserData();
  }, []);

  return (
    <div className="homePage__container_9f8d7a">
      <NavBar />
      <div className="homePage__dashboard_9f8d7a">
        <section className="homePage__welcomeSection_9f8d7a">
          <h2 className="homePage__welcomeHeading_9f8d7a">Welcome, {user}!</h2>
          <div className="homePage__accountInfo_9f8d7a">
            <span className="homePage__balanceLabel_9f8d7a">Balance: Rs {balance}</span>
          </div>
        </section>

        <section className="homePage__notificationsSection_9f8d7a">
          <h3 className="homePage__notificationsHeading_9f8d7a">Notifications</h3>
          <ul className="homePage__notificationsList_9f8d7a">
            {notifications.map((note, idx) => (
              <li className="homePage__notificationItem_9f8d7a" key={idx}>{note}</li>
            ))}
          </ul>
          {loading && <p>Loading notifications...</p>}
{error && <p>Error: {error}</p>}
        </section>

        <section className="homePage__menuSection_9f8d7a">
          <h3 className="homePage__menuHeading_9f8d7a">Today's Menu</h3>
          <div className="homePage__menuList_9f8d7a">
            {menu.map((item) => (
              <div className="homePage__menuCard_9f8d7a" key={item.id}>
                <h4 className="homePage__menuCardTitle_9f8d7a">{item.name}</h4>
                <p className="homePage__menuCardDescription_9f8d7a">{item.description}</p>
                <div className="homePage__menuCardFooter_9f8d7a">
                  <span className="homePage__menuCardPrice_9f8d7a">Rs {item.price}</span>
                  <button className="homePage__menuCardButton_9f8d7a">Add to Cart</button>
                
                {menuLoading && <p>Loading menu...</p>}
{menuError && <p>Error: {menuError}</p>}
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}

export default Home;
