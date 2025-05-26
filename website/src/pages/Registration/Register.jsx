import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import "./Register.css";

const logoImage = "https://upload.wikimedia.org/wikipedia/commons/a/a7/React-icon.svg";
const googleIcon = "https://developers.google.com/identity/images/g-logo.png";
const facebookIcon = "https://upload.wikimedia.org/wikipedia/commons/0/05/Facebook_Logo_%282019%29.png";

const Register = () => {

  const navigate = useNavigate();

  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    password: '',
    confirmPassword: '',
    agreeTerms: false
  });
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
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
    
    // Name validation
    if (!formData.fullName.trim()) {
      newErrors.fullName = 'Full name is required';
    }
    
    // Email validation
    if (!formData.email) {
      newErrors.email = 'Email is required';
    } else if (!/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(formData.email)) {
      newErrors.email = 'Please enter a valid email address';
    }
    
    // Password validation
   const strongPasswordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+{}\[\]:;<>,.?~\\/-]).{8,}$/;

if (!formData.password) {
  newErrors.password = 'Password is required';
} else if (!strongPasswordRegex.test(formData.password)) {
  newErrors.password = 'Password must be at least 8 characters and include uppercase, lowercase, number, and special character';
}
    
    // Confirm password validation
    if (!formData.confirmPassword) {
      newErrors.confirmPassword = 'Please confirm your password';
    } else if (formData.confirmPassword !== formData.password) {
      newErrors.confirmPassword = 'Passwords do not match';
    }
    
    // Terms agreement validation
    if (!formData.agreeTerms) {
      newErrors.agreeTerms = 'You must agree to the Terms and Conditions';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    
    if (validateForm()) {
      // registration logic
        
      
      console.log('Form submitted:', formData);
      
      // Redirect to home page or verification page on successful registration
      navigate('/home');
    }
  };

  const handleSocialRegister = (provider) => {
    console.log(`Register with ${provider}`);
    // Implement social registration logic here
  };

  return (
    <div className="register-container">
      <div className="register-card">
        <div className="register-header">
          <img src={logoImage} alt="Smart Canteen Logo" className="register-logo" />
          <h1>Create Account</h1>
          <p>Sign up to join Smart Canteen</p>
        </div>
        
        <form className="register-form" onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="fullName">Full Name</label>
            <div className="input-wrapper">
              <i className="icon user-icon"></i>
              <input
                type="text"
                id="fullName"
                name="fullName"
                placeholder="Enter your full name"
                value={formData.fullName}
                onChange={handleChange}
                className={errors.fullName ? 'error' : ''}
              />
            </div>
            {errors.fullName && <span className="error-message">{errors.fullName}</span>}
          </div>
          
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
                placeholder="Create a password"
                value={formData.password}
                onChange={handleChange}
                className={errors.password ? 'error' : ''}
              />
              <button 
                type="button" 
                className="toggle-password"
                onClick={() => setShowPassword(!showPassword)}
              >
                <i className={`icon ${showPassword ? 'visibility-icon' : 'visibility-off-icon'}`}></i>
              </button>
            </div>
            {errors.password && <span className="error-message">{errors.password}</span>}
          </div>
          
          <div className="form-group">
            <label htmlFor="confirmPassword">Confirm Password</label>
            <div className="input-wrapper">
              <i className="icon password-icon"></i>
              <input
                type={showConfirmPassword ? 'text' : 'password'}
                id="confirmPassword"
                name="confirmPassword"
                placeholder="Confirm your password"
                value={formData.confirmPassword}
                onChange={handleChange}
                className={errors.confirmPassword ? 'error' : ''}
              />
              <button 
                type="button" 
                className="toggle-password"
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
              >
                <i className={`icon ${showConfirmPassword ? 'visibility-icon' : 'visibility-off-icon'}`}></i>
              </button>
            </div>
            {errors.confirmPassword && <span className="error-message">{errors.confirmPassword}</span>}
          </div>
          
          <div className="terms-agreement">
            <input
              type="checkbox"
              id="agreeTerms"
              name="agreeTerms"
              checked={formData.agreeTerms}
              onChange={handleChange}
              className={errors.agreeTerms ? 'error' : ''}
            />
            <label htmlFor="agreeTerms">
              I agree to the <Link to="/terms" className="terms-link">Terms and Conditions</Link>
            </label>
          </div>
          {errors.agreeTerms && <span className="error-message terms-error">{errors.agreeTerms}</span>}
          
          <button type="submit" className="register-button">REGISTER</button>
          
          <div className="social-register">
            <p>Or Register With</p>
            <div className="social-buttons">
              <button 
                type="button" 
                className="social-button" 
                onClick={() => handleSocialRegister('Google')}
              >
                <img src={googleIcon} alt="Google" />
              </button>
              <button 
                type="button" 
                className="social-button" 
                onClick={() => handleSocialRegister('Facebook')}
              >
                <img src={facebookIcon} alt="Facebook" />
              </button>
            </div>
          </div>
          
          <div className="login-option">
            <p>Already have an account? <Link to="/login" className="login-link">Login</Link></p>
          </div>
        </form>
      </div>
    </div>
  );
};

export default Register;