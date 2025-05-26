import './Features.css';

function Features() {
  const features = [
    {
      iconType: 'img',
      icon: 'https://img.icons8.com/ios-filled/64/0074D9/smartphone-tablet.png',
      title: 'Mobile Ordering',
      description: 'Order food from anywhere on campus using our easy-to-use mobile app/Website.'
    },
    {
      iconType: 'img',
      icon: 'https://img.icons8.com/ios-filled/64/0074D9/clock--v1.png',
      title: 'Real-time Updates',
      description: 'Get real-time notifications about canteen congestion levels, your order status and preparation time.'
    },
    {
      iconType: 'img',
      icon: 'https://img.icons8.com/ios-filled/40/0074D9/wallet-app.png',
      title: 'Secure Payments',
      description: 'Pay securely online with multiple authentication methods.'
    },
    {
      iconType: 'img',
      icon: 'https://img.icons8.com/ios-filled/64/0074D9/cutlery.png',
      title: 'Customized Orders',
      description: 'Customize your meal with specific preferences and dietary requirements.'
    },
    {
      iconType: 'img',
      icon: 'https://img.icons8.com/ios-filled/64/0074D9/gift.png',
      title: 'Loyalty Rewards',
      description: 'Manage your weekly or daily budget with our unique features.'
    },
    {
      iconType: 'img',
      icon: 'https://img.icons8.com/ios-filled/64/0074D9/combo-chart--v1.png',
      title: 'Order History',
      description: 'Keep track of your expenses and easily reorder them with one click.'
    }
  ];

  return (
    <section id="features" className="features">
      <div className="container">
        <h2 className="section-title">Why Choose Smart Canteen?</h2>
        <div className="features-grid">
          {features.map((feature, index) => (
            <div className="feature-card" key={index}>
              <div className="feature-icon">
                {feature.iconType === 'img' ? (
                  <img src={feature.icon} alt={feature.title} style={{ width: '48px', height: '48px' }} />
                ) : (
                  <i className={`fas ${feature.icon}`}></i>
                )}
              </div>
              <h3>{feature.title}</h3>
              <p>{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

export default Features;
