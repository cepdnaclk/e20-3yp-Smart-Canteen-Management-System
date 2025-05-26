import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import "./Login.css"; 

const logoImage = "https://upload.wikimedia.org/wikipedia/commons/a/a7/React-icon.svg";
const googleIcon = "https://developers.google.com/identity/images/g-logo.png";

const facebookIcon = "https://upload.wikimedia.org/wikipedia/commons/0/05/Facebook_Logo_%282019%29.png";

const LoginPage = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    rememberMe: false
  });
  const [showPassword, setShowPassword] = useState(false);
  const [errors, setErrors] = useState({});

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    const newValue = type === 'checkbox' ? checked : value;
    
    setFormData({
      ...formData,
      [name]: newValue
    });
    
    // Clear error when user starts typing
    if (errors[name]) {
      setErrors({
        ...errors,
        [name]: null
      });
    }
  };

  const validateForm = () => {
    const newErrors = {};
    
    // Email validation
    if (!formData.email) {
      newErrors.email = 'Email is required';
    } else if (!/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(formData.email)) {
      newErrors.email = 'Please enter a valid email address';
    }
    
    // Password validation
    if (!formData.password) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 6) {
      newErrors.password = 'Password must be at least 6 characters';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (validateForm()) {
        
      try{
        const response = await fetch('api/login',{
          method:'POST',
          headers:{
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            email: formData.email,
            password: formData.password,
            rememberMe: formData.rememberMe
          })
        });
        if (!response.ok) {
          const errorData = await response.json();
          setErrors({ form: errorData.message || 'Login failed' });
          return;
        }
        //get user token
        const data = await response.json();
        localStorage.setItem('userToken', data.token);
        navigate('/home');
      }catch (error) {
        console.error('Error during login:', error);
        setErrors({ form: 'An error occurred during login' });
      }

      
      console.log('Form submitted:', formData);
      
      // Redirect to home page on successful login
      navigate('/home');
    }
  };

  const handleSocialLogin = (provider) => {
    console.log(`Login with ${provider}`);
    
  };

  return (
    <div className="login-container">
      <div className="login-card">
        <div className="login-header">
          <img src={logoImage} alt="Smart Canteen Logo" className="login-logo" />
          <h1>Welcome Back!</h1>
          <p>Sign in to continue to Smart Canteen</p>
        </div>
        
        <form className="login-form" onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="email">Email</label>
            <div className="input-wrapper">
              <i className="icon email-icon"></i>
              <input
                type="email"
                id="email"
                name="email"
                placeholder="Enter your email"
                value={formData.email}
                onChange={handleChange}
                className={errors.email ? 'error' : ''}
              />
            </div>
            {errors.email && <span className="error-message">{errors.email}</span>}
          </div>
          
          <div className="form-group">
            <label htmlFor="password">Password</label>
            
            <div className="input-wrapper">
              <i className="icon password-icon"></i>
              <input
                type={showPassword ? 'text' : 'password'}
                id="password"
                name="password"
                placeholder="Enter your password"
                value={formData.password}
                onChange={handleChange}
                className={errors.password ? 'error' : ''}
              />
              <button 
                type="button" 
                className="toggle-password"
                onClick={() => setShowPassword(!showPassword)}
                tabIndex={-1} 
              >
                <i className={`icon ${showPassword ? 'visibility-icon' : 'visibility-off-icon'}`}></i>
              </button>
            </div>
            {errors.password && <span className="error-message">{errors.password}</span>}
          </div>
          
          <div className="login-options">
            <div className="remember-me">
              <input
                type="checkbox"
                id="rememberMe"
                name="rememberMe"
                checked={formData.rememberMe}
                onChange={handleChange}
              />
              <label htmlFor="rememberMe">Remember me</label>
            </div>
            <Link to="/forgot-password" className="forgot-password">Forgot Password?</Link>
          </div>
          
          <button type="submit" className="login-button">LOGIN</button>
          {errors.form && <span className="error-message form-error">{errors.form}</span>}
          
          <div className="social-login">
            <p>Or Login With</p>
            <div className="social-buttons">
              <button 
                type="button" 
                className="social-button" 
                onClick={() => handleSocialLogin('Google')}
              >
                <img src={googleIcon} alt="Google" />
              </button>
              <button 
                type="button" 
                className="social-button" 
                onClick={() => handleSocialLogin('Facebook')}
              >
                <img src={facebookIcon} alt="Facebook" />
              </button>
            </div>
          </div>
          
          <div className="register-option">
            <p>Don't have an account? <Link to="/register" className="register-link">Register</Link></p>
          </div>
        </form>
      </div>
    </div>
  );
};

export default LoginPage;