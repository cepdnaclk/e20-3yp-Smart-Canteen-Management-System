import React, { useState } from 'react';
import { Link } from 'react-router-dom';

import NavBar from '../../components/NavBar/NavBar';

import './ContactPage.css';

// Import images (paths would need to be adjusted based on your project structure)
const contactImage = "/images/contact-image.jpg";
const mapImage = "/images/campus-map.jpg";

const ContactPage = () => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    subject: '',
    message: '',
  });
  
  const [errors, setErrors] = useState({});
  const [submitStatus, setSubmitStatus] = useState(null);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value,
    });
    
    // Clear error when user starts typing
    if (errors[name]) {
      setErrors({
        ...errors,
        [name]: null,
      });
    }
  };

  const validateForm = () => {
    const newErrors = {};
    
    // Name validation
    if (!formData.name.trim()) {
      newErrors.name = 'Name is required';
    }
    
    // Email validation
    if (!formData.email) {
      newErrors.email = 'Email is required';
    } else if (!/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(formData.email)) {
      newErrors.email = 'Please enter a valid email address';
    }
    
    // Phone validation (optional)
    if (formData.phone && !/^[0-9\-\+\(\)\s]+$/.test(formData.phone)) {
      newErrors.phone = 'Please enter a valid phone number';
    }
    
    // Subject validation
    if (!formData.subject) {
      newErrors.subject = 'Subject is required';
    }
    
    // Message validation
    if (!formData.message.trim()) {
      newErrors.message = 'Message is required';
    } else if (formData.message.trim().length < 10) {
      newErrors.message = 'Message must be at least 10 characters';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    
    if (validateForm()) {
      // Simulate API call
      setSubmitStatus('sending');
      
      // Simulate a successful response after a delay
      setTimeout(() => {
        setSubmitStatus('success');
        setFormData({
          name: '',
          email: '',
          phone: '',
          subject: '',
          message: '',
        });
        
        // Reset success message after 5 seconds
        setTimeout(() => {
          setSubmitStatus(null);
        }, 5000);
      }, 1500);
    }
  };

  return (
    <div className="contact-container">
      <NavBar/>
      {/* Hero Section */}
      <section className="contact-hero">
        <div className="hero-content">
          <h1>Get in <span className="highlight">Touch</span></h1>
          <p>We'd love to hear from you! Reach out to our team with any questions, suggestions, or partnership inquiries.</p>
        </div>
        <div className="hero-image">
          <img src={contactImage} alt="Smart Canteen Customer Support" />
        </div>
      </section>

      {/* Contact Info Section */}
      <section className="contact-info">
        <div className="section-header">
          <h2>Contact Information</h2>
          <div className="section-divider"></div>
        </div>
        
        <div className="info-cards">
          <div className="info-card">
            <div className="info-icon location"></div>
            <h3>Our Location</h3>
            <p>123 University Avenue</p>
            <p>Tech Hub, Building 5</p>
            <p>Innovation District, CA 94107</p>
          </div>
          
          <div className="info-card">
            <div className="info-icon phone"></div>
            <h3>Phone Numbers</h3>
            <p>General Inquiries: (555) 123-4567</p>
            <p>Customer Support: (555) 987-6543</p>
            <p>Business Relations: (555) 567-8901</p>
          </div>
          
          <div className="info-card">
            <div className="info-icon email"></div>
            <h3>Email Us</h3>
            <p>info@smartcanteen.com</p>
            <p>support@smartcanteen.com</p>
            <p>partnerships@smartcanteen.com</p>
          </div>
          
          <div className="info-card">
            <div className="info-icon hours"></div>
            <h3>Office Hours</h3>
            <p>Monday - Friday: 9:00 AM - 6:00 PM</p>
            <p>Saturday: 10:00 AM - 2:00 PM</p>
            <p>Sunday: Closed</p>
          </div>
        </div>
      </section>

      {/* Contact Form Section */}
      <section className="contact-form-section">
        <div className="form-container">
          <div className="section-header">
            <h2>Send Us a Message</h2>
            <div className="section-divider"></div>
            <p className="section-intro">Have questions or need assistance? Fill out the form below and we'll get back to you shortly.</p>
          </div>
          
          <form className="contact-form" onSubmit={handleSubmit}>
            <div className="form-group">
              <label htmlFor="name">Full Name<span className="required">*</span></label>
              <input
                type="text"
                id="name"
                name="name"
                placeholder="Enter your full name"
                value={formData.name}
                onChange={handleChange}
                className={errors.name ? 'error' : ''}
              />
              {errors.name && <span className="error-message">{errors.name}</span>}
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="email">Email Address<span className="required">*</span></label>
                <input
                  type="email"
                  id="email"
                  name="email"
                  placeholder="Enter your email"
                  value={formData.email}
                  onChange={handleChange}
                  className={errors.email ? 'error' : ''}
                />
                {errors.email && <span className="error-message">{errors.email}</span>}
              </div>
              
              <div className="form-group">
                <label htmlFor="phone">Phone Number (optional)</label>
                <input
                  type="tel"
                  id="phone"
                  name="phone"
                  placeholder="Enter your phone number"
                  value={formData.phone}
                  onChange={handleChange}
                  className={errors.phone ? 'error' : ''}
                />
                {errors.phone && <span className="error-message">{errors.phone}</span>}
              </div>
            </div>
            
            <div className="form-group">
              <label htmlFor="subject">Subject<span className="required">*</span></label>
              <select
                id="subject"
                name="subject"
                value={formData.subject}
                onChange={handleChange}
                className={errors.subject ? 'error' : ''}
              >
                <option value="">Select a subject</option>
                <option value="General Inquiry">General Inquiry</option>
                <option value="Technical Support">Technical Support</option>
                <option value="Partnership">Partnership Opportunity</option>
                <option value="Campus Integration">Campus Integration</option>
                <option value="Feedback">Feedback</option>
                <option value="Other">Other</option>
              </select>
              {errors.subject && <span className="error-message">{errors.subject}</span>}
            </div>
            
            <div className="form-group">
              <label htmlFor="message">Message<span className="required">*</span></label>
              <textarea
                id="message"
                name="message"
                placeholder="Type your message here..."
                rows="5"
                value={formData.message}
                onChange={handleChange}
                className={errors.message ? 'error' : ''}
              ></textarea>
              {errors.message && <span className="error-message">{errors.message}</span>}
            </div>
            
            <div className="form-submit">
              <button type="submit" className="submit-button" disabled={submitStatus === 'sending'}>
                {submitStatus === 'sending' ? 'Sending...' : 'Send Message'}
              </button>
              {submitStatus === 'success' && (
                <div className="success-message">
                  <p>Your message has been sent successfully! We'll get back to you soon.</p>
                </div>
              )}
            </div>
          </form>
        </div>
        
        <div className="location-container">
          <div className="map-container">
            <img src={mapImage} alt="Campus Location Map" className="campus-map" />
            <div className="map-overlay">
              <h3>Campus Locations</h3>
              <p>Smart Canteen is available across multiple campuses nationwide. Find us at your institution!</p>
              <Link to="/locations" className="view-locations-btn">View All Locations</Link>
            </div>
          </div>
        </div>
      </section>

      {/* FAQ Section */}
      <section className="faq-section">
        <div className="section-header">
          <h2>Frequently Asked Questions</h2>
          <div className="section-divider"></div>
        </div>
        
        <div className="faq-container">
          <div className="faq-item">
            <div className="faq-question">
              <h3>How do I integrate Smart Canteen at my campus?</h3>
              <div className="question-icon"></div>
            </div>
            <div className="faq-answer">
              <p>We offer comprehensive integration services for universities and colleges. Our team will work with your administration to customize the Smart Canteen platform to your specific needs. Contact our business team at partnerships@smartcanteen.com to schedule a consultation.</p>
            </div>
          </div>
          
          <div className="faq-item">
            <div className="faq-question">
              <h3>What technical support do you provide?</h3>
              <div className="question-icon"></div>
            </div>
            <div className="faq-answer">
              <p>Our technical support team is available Monday through Friday from 8:00 AM to 8:00 PM. We provide comprehensive support for both administrators and end-users through email, phone, and live chat. For urgent matters, we also offer weekend support.</p>
            </div>
          </div>
          
          <div className="faq-item">
            <div className="faq-question">
              <h3>Do you offer custom solutions for specialized campus needs?</h3>
              <div className="question-icon"></div>
            </div>
            <div className="faq-answer">
              <p>Yes! We understand that each campus has unique requirements. Our development team can create custom modules and features tailored to your specific dining services, payment systems, and campus logistics. Contact us to discuss your specific needs.</p>
            </div>
          </div>
          
          <div className="faq-item">
            <div className="faq-question">
              <h3>How long does implementation typically take?</h3>
              <div className="question-icon"></div>
            </div>
            <div className="faq-answer">
              <p>Basic implementation can be completed in as little as 2-4 weeks. More complex integrations with existing campus systems may take 6-8 weeks. Our implementation specialists will provide you with a detailed timeline based on your specific requirements.</p>
            </div>
          </div>
        </div>
        
        <div className="more-questions">
          <p>Still have questions? Contact our team or check our <Link to="/faq" className="faq-link">complete FAQ page</Link>.</p>
        </div>
      </section>

      {/* Connect Section */}
      <section className="connect-section">
        <div className="connect-container">
          <h2>Connect With Us</h2>
          <p>Follow us on social media for updates, tips, and campus food inspiration.</p>
          
          <div className="social-icons">
            <a href="https://facebook.com" target="_blank" rel="noopener noreferrer" className="social-icon facebook"></a>
            <a href="https://twitter.com" target="_blank" rel="noopener noreferrer" className="social-icon twitter"></a>
            <a href="https://instagram.com" target="_blank" rel="noopener noreferrer" className="social-icon instagram"></a>
            <a href="https://linkedin.com" target="_blank" rel="noopener noreferrer" className="social-icon linkedin"></a>
            <a href="https://youtube.com" target="_blank" rel="noopener noreferrer" className="social-icon youtube"></a>
          </div>
        </div>
      </section>
    </div>
  );
};

export default ContactPage;