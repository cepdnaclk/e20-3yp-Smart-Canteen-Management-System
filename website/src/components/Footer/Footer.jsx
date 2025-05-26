// src/components/Footer/Footer.jsx
import { useState } from 'react';
import './Footer.css';

function Footer() {
  const [email, setEmail] = useState('');
  
  const handleSubmit = (e) => {
    e.preventDefault();
    // Here you would typically handle the newsletter subscription
    alert(`Thank you for subscribing with ${email}!`);
    setEmail('');
  };
  
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-content">
          <div className="footer-section about">
            <div className="logo">
              <img src="/images/logo.png" alt="Smart Canteen" />
              <h2>Smart Canteen</h2>
            </div>
            <p>Making campus dining smarter, faster, and more convenient. Order ahead and skip the lines with our innovative mobile ordering system.</p>
            <div className="social-icons">
              <a href="#" aria-label="Facebook"><i className="fab fa-facebook-f"></i></a>
              <a href="#" aria-label="Twitter"><i className="fab fa-twitter"></i></a>
              <a href="#" aria-label="Instagram"><i className="fab fa-instagram"></i></a>
              <a href="#" aria-label="LinkedIn"><i className="fab fa-linkedin-in"></i></a>
            </div>
          </div>
          
          <div className="footer-section links">
            <h3>Quick Links</h3>
            <ul>
              <li><a href="#home">Home</a></li>
              <li><a href="#features">Features</a></li>
              <li><a href="#popular-items">Menu</a></li>
              <li><a href="#how-it-works">How It Works</a></li>
              <li><a href="#testimonials">Testimonials</a></li>
              <li><a href="#faq">FAQ</a></li>
            </ul>
          </div>
          
          <div className="footer-section contact">
            <h3>Contact Us</h3>
            <div className="contact-info">
              <p><i className="fas fa-map-marker-alt"></i> University Of Peradeniya, Peradeniya</p>
              <p><i className="fas fa-phone"></i> (+94) 12-456-7890</p>
              <p><i className="fas fa-envelope"></i> info@smartcanteen.com</p>
            </div>
          </div>
          
          <div className="footer-section newsletter">
            <h3>Subscribe to Our Newsletter</h3>
            <p>Stay updated with our latest offers and news.</p>
            <form onSubmit={handleSubmit}>
              <input 
                type="email" 
                placeholder="Enter your email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
              <button type="submit">Subscribe</button>
            </form>
          </div>
        </div>
        
        <div className="footer-bottom">
          <p>&copy; {new Date().getFullYear()} Smart Canteen. All Rights Reserved.</p>
          <div className="footer-bottom-links">
            <a href="/terms">Terms of Service</a>
            <a href="/privacy">Privacy Policy</a>
          </div>
        </div>
      </div>
    </footer>
  );
}

export default Footer;