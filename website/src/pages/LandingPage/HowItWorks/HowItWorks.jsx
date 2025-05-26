import './HowItWorks.css';

function HowItWorks() {
  const steps = [
    {
      number: 1,
      title: 'Browse the Menu',
      description: 'Explore our diverse menu options from all campus dining locations in one place.',
      iconUrl: 'https://img.icons8.com/ios-filled/50/0074D9/restaurant-menu.png' // menu icon
    },
    {
      number: 2,
      title: 'Place Your Order',
      description: 'Select your items, customize as needed, and add them to your cart.',
      iconUrl: 'https://img.icons8.com/ios-filled/50/0074D9/shopping-cart.png' // shopping cart icon
    },
    {
      number: 3,
      title: 'Pay Securely',
      description: 'Complete your order using our secure payment system with multiple options.',
      iconUrl: 'https://img.icons8.com/ios-filled/50/0074D9/credit-card.png' // credit card icon
    },
    {
      number: 4,
      title: 'Track Preparation',
      description: 'Follow real-time updates as your order is being prepared.',
      iconUrl: 'https://img.icons8.com/ios-filled/50/0074D9/clock.png' // clock icon
    },
    {
      number: 5,
      title: 'Pick Up & Enjoy',
      description: 'Skip the line with designated pickup locations across campus.',
      iconUrl: 'https://img.icons8.com/ios-filled/50/0074D9/checkmark.png' // checkmark icon
    }
  ];

  return (
    <section id="how-it-works" className="how-it-works">
      <div className="container">
        <h2 className="section-title">How It Works</h2>
        <p className="section-description">
          Smart Canteen makes ordering food on campus quick and convenient in just a few simple steps.
        </p>
        
        <div className="steps-container">
          {steps.map((step, index) => (
            <div className="step-card" key={index}>
              <div className="step-number">{step.number}</div>
              <div className="step-icon">
                <img 
                  src={step.iconUrl} 
                  alt={`${step.title} icon`} 
                  width="40" 
                  height="40" 
                  style={{ filter: 'invert(26%) sepia(87%) saturate(2081%) hue-rotate(183deg) brightness(91%) contrast(89%)' }} 
                />
              </div>
              <h3>{step.title}</h3>
              <p>{step.description}</p>
            </div>
          ))}
        </div>
        
        <div className="download-app">
          <h3>Get Started Now</h3>
          <p>Download our mobile app to experience seamless campus dining</p>
          <div className="app-buttons">
            <a href="#" className="app-button app-store">
              <img 
                src="https://img.icons8.com/ios-filled/24/ffffff/mac-os.png" 
                alt="App Store" 
                style={{ marginRight: '8px' }} 
              />
              App Store
            </a>
            <a href="#" className="app-button google-play">
              <img 
                src="https://img.icons8.com/ios-filled/24/ffffff/google-play.png" 
                alt="Google Play" 
                style={{ marginRight: '8px' }} 
              />
              Google Play
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}

export default HowItWorks;
