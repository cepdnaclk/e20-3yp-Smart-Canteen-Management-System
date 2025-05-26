import React from 'react';
import { Link } from 'react-router-dom';

import NavBar from '../../components/NavBar/NavBar';

import './About.css';

// Online images for demo
const teamImage = "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80";
const founderImage = "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80";
const missionImage = "https://images.unsplash.com/photo-1497493292307-31c376b6e479?auto=format&fit=crop&w=800&q=80";
const techImage = "https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=800&q=80";

const AboutPage = () => {
  return (
    
    <div className="about-unique-container">
      <NavBar/>
      {/* Hero Section */}
      <section className="about-unique-hero">
        <div className="about-unique-hero-content">
          <h1>
            About <span className="about-unique-highlight">Smart Canteen</span>
          </h1>
          <p>
            Transforming campus dining experiences with innovative technology and exceptional service
          </p>
          <div className="about-unique-hero-cta">
            <Link to="/contact" className="about-unique-cta-button">Contact Us</Link>
            <Link to="/register" className="about-unique-cta-button about-unique-secondary">Join Now</Link>
          </div>
        </div>
        <div className="about-unique-hero-image">
          <img src={teamImage} alt="Smart Canteen Team" />
        </div>
      </section>

      {/* Our Story Section */}
      <section className="about-unique-our-story">
        <div className="about-unique-section-header">
          <h2>Our Story</h2>
          <div className="about-unique-section-divider"></div>
        </div>
        <div className="about-unique-story-content">
          <p>
            Smart Canteen was founded in 2025 by a group of university students as their 3rd year project who were frustrated with long canteen queues and 
            limited food options. What started as a simple solution to a common problem has grown into a comprehensive platform serving thousands of students across multiple campuses.
          </p>
          <p>
            From our humble beginnings, we've expanded our services to provide not just ordering capabilities, but a 
            complete ecosystem that connects students with quality food options while helping canteen operators streamline 
            their operations and reduce waste.
          </p>
        </div>
      </section>

      {/* Mission and Vision */}
      <section className="about-unique-mission-vision">
        <div className="about-unique-mission">
          <div className="about-unique-content-image">
            <img src={missionImage} alt="Our Mission" />
          </div>
          <div className="about-unique-content-text">
            <h3>Our Mission</h3>
            <p>
              To revolutionize campus dining by providing convenient, accessible, and personalized food services 
              that enhance student life and support sustainable food practices.
            </p>
            <ul className="about-unique-mission-points">
              <li>Make campus dining stress-free and enjoyable</li>
              <li>Reduce food waste through smart ordering systems</li>
              <li>Notifications for real-time updates</li>
            </ul>
          </div>
        </div>
        <div className="about-unique-vision">
          <div className="about-unique-content-text">
            <h3>Our Vision</h3>
            <p>
              We envision a future where every campus has access to Smart Canteen services, creating 
              efficient, sustainable, and enjoyable dining experiences for students worldwide.
            </p>
            <div className="about-unique-vision-stats">
              <div className="about-unique-stat">
                <span className="about-unique-stat-number">5,000+</span>
                <span className="about-unique-stat-label">Daily Orders</span>
              </div>
              <div className="about-unique-stat">
                <span className="about-unique-stat-number">15+</span>
                <span className="about-unique-stat-label">Campus Locations</span>
              </div>
              <div className="about-unique-stat">
                <span className="about-unique-stat-number">98%</span>
                <span className="about-unique-stat-label">Satisfaction Rate</span>
              </div>
            </div>
          </div>
          <div className="about-unique-content-image">
            <img src={techImage} alt="Our Vision" />
          </div>
        </div>
      </section>

      {/* Core Values */}
      <section className="about-unique-core-values">
        <div className="about-unique-section-header">
          <h2>Our Core Values</h2>
          <div className="about-unique-section-divider"></div>
        </div>
        <div className="about-unique-values-grid">
          <div className="about-unique-value-card">
            <div className="about-unique-value-icon about-unique-innovation"></div>
            <h3>Innovation</h3>
            <p>Constantly improving our platform with cutting-edge technology to enhance user experience.</p>
          </div>
          <div className="about-unique-value-card">
            <div className="about-unique-value-icon about-unique-quality"></div>
            <h3>Quality</h3>
            <p>Ensuring high standards in every aspect of our service, from app performance to food selection.</p>
          </div>
          <div className="about-unique-value-card">
            <div className="about-unique-value-icon about-unique-community"></div>
            <h3>Community</h3>
            <p>Building meaningful connections between students, food providers, and campus administrators.</p>
          </div>
          <div className="about-unique-value-card">
            <div className="about-unique-value-icon about-unique-sustainability"></div>
            <h3>Sustainability</h3>
            <p>Promoting eco-friendly practices through reduced food waste and efficient resource management.</p>
          </div>
        </div>
      </section>

      {/* Our Team */}
      <section className="about-unique-leadership">
        <div className="about-unique-section-header">
          <h2>Our Team</h2>
          <div className="about-unique-section-divider"></div>
        </div>
        <div className="about-unique-team-grid">
          <div className="about-unique-team-member">
            <div className="about-unique-member-photo">
              <img src={founderImage} alt="Sarah Johnson" />
            </div>
            <h3>Pathum Dilhara</h3>
            <p className="about-unique-member-title">Student</p>
            <p className="about-unique-member-bio">Computer Engineering Undergraduate @ University of Peradeniya .</p>
          </div>
          <div className="about-unique-team-member">
            <div className="about-unique-member-photo">
              <img src={founderImage} alt="Michael Chen" />
            </div>
            <h3>Maleesha Shehan</h3>
            <p className="about-unique-member-title">Student</p>
            <p className="about-unique-member-bio">Computer Science Undergraduate @ University of Peradeniya.</p>
          </div>
          <div className="about-unique-team-member">
            <div className="about-unique-member-photo">
              <img src={founderImage} alt="Priya Patel" />
            </div>
            <h3>Sandun Lakshan</h3>
            <p className="about-unique-member-title">Student</p>
            <p className="about-unique-member-bio">Computer Engineering Undergraduate @ University of Peradeniya .</p>
          </div>
          <div className="about-unique-team-member">
            <div className="about-unique-member-photo">
              <img src={founderImage} alt="James Wilson" />
            </div>
            <h3>Manuja Shayamantha</h3>
            <p className="about-unique-member-title">Student</p>
            <p className="about-unique-member-bio">Computer Engineering Undergraduate @ University of Peradeniya .</p>
          </div>
        </div>
      </section>

      {/* Growth and Impact */}
      <section className="about-unique-growth-impact">
        <div className="about-unique-section-header">
          <h2>Our Growth & Impact</h2>
          <div className="about-unique-section-divider"></div>
        </div>
        <div className="about-unique-timeline">
          <div className="about-unique-timeline-item">
            <div className="about-unique-timeline-marker">2025</div>
            <div className="about-unique-timeline-content">
              <h3>The Beginning</h3>
              <p>Launched at University Of Peradeniya with basic ordering features</p>
            </div>
          </div>
          <div className="about-unique-timeline-item">
            <div className="about-unique-timeline-marker">2025</div>
            <div className="about-unique-timeline-content">
              <h3>Expansion</h3>
              <p>Added 5 new campuses and introduced loyalty rewards</p>
            </div>
          </div>
          <div className="about-unique-timeline-item">
            <div className="about-unique-timeline-marker">2025</div>
            <div className="about-unique-timeline-content">
              <h3>Technology Update</h3>
              <p>Revamped platform with real-time tracking and personalization</p>
            </div>
          </div>
          <div className="about-unique-timeline-item">
            <div className="about-unique-timeline-marker">2025</div>
            <div className="about-unique-timeline-content">
              <h3>Going National</h3>
              <p>Expanded to 15+ campuses nationwide with full-service features</p>
            </div>
          </div>
          <div className="about-unique-timeline-item">
            <div className="about-unique-timeline-marker">2025</div>
            <div className="about-unique-timeline-content">
              <h3>Sustainability Focus</h3>
              <p>Implemented eco-friendly initiatives reducing campus food waste by 30%</p>
            </div>
          </div>
        </div>
      </section>

      {/* Join Us CTA */}
      <section className="about-unique-join-us">
        <div className="about-unique-join-content">
          <h2>Be Part of Our Journey</h2>
          <p>
            Whether you're a student looking for convenient dining, a campus administrator interested in 
            improving food services, or a canteen operator wanting to streamline operations – 
            we'd love to work with you.
          </p>
          <div className="about-unique-join-cta">
            <Link to="/register" className="about-unique-cta-button">Sign Up Today</Link>
            <Link to="/contact" className="about-unique-cta-button about-unique-secondary">Contact Sales</Link>
          </div>
        </div>
      </section>
    </div>
  );
};

export default AboutPage;
