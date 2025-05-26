import { useState } from 'react';
import './FAQ.css';

const faqData = [
  {
    id: 1,
    question: 'How do I place an order?',
    answer: 'Simply browse the menu, select your items, customize if needed, and add them to your cart. Then proceed to checkout and pay securely.',
    iconUrl: 'https://img.icons8.com/ios-filled/40/0074D9/shopping-cart.png'
  },
  {
    id: 2,
    question: 'Can I customize my meals?',
    answer: 'Yes! You can customize your orders with specific preferences and dietary requirements directly in the app.',
    iconUrl: 'https://img.icons8.com/ios-filled/40/0074D9/settings.png'
  },
  {
    id: 3,
    question: 'What payment methods are accepted?',
    answer: 'We accept credit/debit cards, mobile wallets, and campus payment options for your convenience.',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/196/196561.png'
    //https://img.icons8.com/ios-filled/40/0074D9/wallet-app.png
  },
  {
    id: 4,
    question: 'How do loyalty rewards work?',
    answer: 'Earn points with every purchase and redeem them for discounts or free meals. Check your rewards balance in the app.',
    iconUrl: 'https://img.icons8.com/ios-filled/40/0074D9/gift.png'
  },
  {
    id: 5,
    question: 'Can I track my order?',
    answer: 'Absolutely! Get real-time updates on your order status and estimated pickup time.',
    iconUrl: 'https://img.icons8.com/ios-filled/40/0074D9/clock.png'
  }
];

function FAQ() {
  const [activeId, setActiveId] = useState(null);

  const toggleFAQ = (id) => {
    setActiveId(activeId === id ? null : id);
  };

  return (
    <section id="faq" className="faq-section">
      <div className="container">
        <h2 className="section-title">Frequently Asked Questions</h2>
        <div className="faq-list">
          {faqData.map(({ id, question, answer, iconUrl }) => (
            <div 
              key={id} 
              className={`faq-item ${activeId === id ? 'active' : ''}`}
              onClick={() => toggleFAQ(id)}
              tabIndex={0}
              onKeyDown={(e) => { if (e.key === 'Enter') toggleFAQ(id); }}
              aria-expanded={activeId === id}
              role="button"
            >
              <div className="faq-question">
                <img src={iconUrl} alt="" className="faq-icon" aria-hidden="true" />
                <h3>{question}</h3>
                <span className="faq-toggle-icon">{activeId === id ? '−' : '+'}</span>
              </div>
              <div className="faq-answer">
                <p>{answer}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

export default FAQ;
