import { useState } from 'react';
import './Testimonials.css';

function Testimonials() {
  const [activeIndex, setActiveIndex] = useState(0);

  const testimonials = [
    {
      id: 1,
      name: 'Ruwan Perera',
      role: 'Computer Science Student',
      image: 'https://randomuser.me/api/portraits/women/44.jpg',
      text: 'Smart Canteen has completely transformed my campus dining experience. I can order between classes and pick up my food without waiting in long lines. The app is intuitive and the order tracking feature is a game changer!',
      rating: 5
    },
    {
      id: 2,
      name: 'Chamara Silva',
      role: 'Business Administration Major',
      image: 'https://randomuser.me/api/portraits/men/32.jpg',
      text: 'As someone with a packed schedule, Smart Canteen has been a lifesaver. I can customize my orders according to my dietary needs, and the loyalty rewards program actually saves me money over time.',
      rating: 5
    },
    {
      id: 3,
      name: 'Dilan Jayawardena',
      role: 'Engineering Student',
      image: 'https://randomuser.me/api/portraits/women/65.jpg',
      text: 'I love how Smart Canteen integrates all campus dining options in one place. The real-time updates are really helpful, and being able to schedule orders in advance has improved my time management significantly.',
      rating: 4
    },
    {
      id: 4,
      name: 'Nadeesha Senanayake',
      role: 'Graduate Student',
      image: 'https://randomuser.me/api/portraits/men/83.jpg',
      text: 'The variety of food options available through Smart Canteen is impressive. The app is reliable, and customer service has been responsive whenever I\'ve needed assistance with my orders.',
      rating: 5
    }
  ];

  const nextTestimonial = () => {
    setActiveIndex((prevIndex) =>
      prevIndex === testimonials.length - 1 ? 0 : prevIndex + 1
    );
  };

  const prevTestimonial = () => {
    setActiveIndex((prevIndex) =>
      prevIndex === 0 ? testimonials.length - 1 : prevIndex - 1
    );
  };

  const goToTestimonial = (index) => {
    setActiveIndex(index);
  };

  return (
    <section id="testimonials" className="testimonials">
      <div className="container">
        <h2 className="section-title">What Students Say</h2>

        <div className="testimonial-slider">
          <button className="slider-btn prev-btn" onClick={prevTestimonial}>
            <i className="fas fa-chevron-left"></i>
          </button>

          <div className="testimonial-wrapper">
            {testimonials.map((testimonial, index) => (
              <div
                className={`testimonial-card ${index === activeIndex ? 'active' : ''}`}
                key={testimonial.id}
                style={{ transform: `translateX(${(index - activeIndex) * 100}%)` }}
              >
                <div className="testimonial-content">
                  <div className="quote-icon">
                    <i className="fas fa-quote-left"></i>
                  </div>
                  <p className="testimonial-text">{testimonial.text}</p>
                  <div className="testimonial-rating">
                    {[...Array(5)].map((_, i) => (
                      <i
                        key={i}
                        className={`fas fa-star ${i < testimonial.rating ? 'filled' : ''}`}
                      ></i>
                    ))}
                  </div>
                </div>
                <div className="testimonial-author">
                  <div className="author-image">
                    <img src={testimonial.image} alt={testimonial.name} />
                  </div>
                  <div className="author-info">
                    <h4>{testimonial.name}</h4>
                    <p>{testimonial.role}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>

          <button className="slider-btn next-btn" onClick={nextTestimonial}>
            <i className="fas fa-chevron-right"></i>
          </button>
        </div>

        <div className="testimonial-dots">
          {testimonials.map((_, index) => (
            <button
              key={index}
              className={`dot ${index === activeIndex ? 'active' : ''}`}
              onClick={() => goToTestimonial(index)}
            ></button>
          ))}
        </div>

        <div className="testimonial-stats">
          <div className="stat-item">
            <h3>5000+</h3>
            <p>Daily Orders</p>
          </div>
          <div className="stat-item">
            <h3>15+</h3>
            <p>Campus Locations</p>
          </div>
          <div className="stat-item">
            <h3>98%</h3>
            <p>Satisfaction Rate</p>
          </div>
          <div className="stat-item">
            <h3>4.8/5</h3>
            <p>App Rating</p>
          </div>
        </div>
      </div>
    </section>
  );
}

export default Testimonials;
