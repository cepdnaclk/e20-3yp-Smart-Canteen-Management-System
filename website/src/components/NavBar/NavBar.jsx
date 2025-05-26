import { useState } from 'react';
import './/NavBar.css';

import logo from '../../assets/pexels-pixabay-258174.jpg'; 

import { Link } from 'react-router-dom';



function NavBar() {
  const [menuOpen, setMenuOpen] = useState(false);
  
  const toggleMenu = () => {
    setMenuOpen(!menuOpen);
  };

  const checkLoggedIn = () => {
    const token = localStorage.getItem('token');
    return token ? true : false;
  };

  const handleLandHomeButton = ()=>{
    if(checkLoggedIn()){
      return "/home";
    }else{
      return "/landing"
    }
  }

  return (
    <nav className={menuOpen ? 'nav-open' : ''}>
      <div className="nav-brand">
        <img src={logo} alt="Logo" className="logo" />
        
        <h1>Smart Canteen</h1>
        <div className="hamburger" onClick={toggleMenu}>
          <span></span>
          <span></span>
          <span></span>
        </div>
      </div>
      <ul className={menuOpen ? 'show' : ''}>
        <li><Link to={handleLandHomeButton()}>Home</Link></li>
        <li><Link to="/menu">Menu</Link></li>
        <li><Link to="/myorders">My Orders</Link></li>
        <li><Link to="/contact">Contact</Link></li>
        <li><Link to="/about">About</Link></li>
        <li><Link to="/login">Login</Link></li>
        <li><Link to="/register">Register</Link></li>
      </ul>
    </nav>
  );
}

export default NavBar;