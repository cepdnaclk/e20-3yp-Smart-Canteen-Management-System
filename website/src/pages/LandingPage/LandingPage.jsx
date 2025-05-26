import React from "react";

import NavBar from "../../components/NavBar/NavBar";
import Hero from "./Hero/HeroSection";
import Features from "./Features/FeatureSection";
import PopularItems from "./PopularItems/PopularItems";
import HowItWorks from "./HowItWorks/HowItWorks";
import Testimonials from "./Testimonials/TestimonialSection";
import FAQ from "./FAQ/FAQ";
import Footer from "../../components/Footer/Footer";
//import "../pagecss/LandingPage.css";

const LandingPage = () => {
    return (
    <div className="App">
      <NavBar />
      <main>
        <Hero />
        <Features />
        <PopularItems />
        <HowItWorks />
        <Testimonials />
        <FAQ />
        <Footer />
      </main>
    </div>
  );
}

export default LandingPage;