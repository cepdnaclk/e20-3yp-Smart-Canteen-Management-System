import React from "react";
import heroImg from "../../../assets/hero-image.jpg"; // Place your hero image here

import "./Hero.css";

function Hero() {
  return (
    <section className="hero-section">
      <div className="hero-inner">
        <div className="hero-content">
          <h1>
            Order Food <span className="highlight">Smarter</span>, Not Harder
          </h1>
          <p>
            Skip the lines and enjoy delicious meals at your campus with our Smart Canteen app. Order ahead, pay online, and get notified when your food is ready.
          </p>
          <div className="hero-buttons">
            <a href="#order" className="btn btn-primary">Order Now</a>
            <a href="#menu" className="btn btn-outline">View Menu</a>
          </div>
          <div className="hero-stats">
            <div className="stat">
              <h3>1000+</h3>
              <p>Daily Orders</p>
            </div>
            <div className="stat">
              <h3>4.8</h3>
              <p>App Rating</p>
            </div>
            <div className="stat">
              <h3>15+</h3>
              <p>Campus Locations</p>
            </div>
          </div>
        </div>
        <div className="hero-image">
          <img src={heroImg} alt="Smart Canteen App" />
          <div className="notification-popup">
            <p>Your order is ready for pickup!</p>
          </div>
        </div>
      </div>
    </section>
  );
}

export default Hero;
