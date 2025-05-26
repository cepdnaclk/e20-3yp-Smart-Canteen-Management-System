import React from "react";

function validateEmail(email) {
    
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    
    // Test the email
    return emailRegex.test(email);
}

export default validateEmail;
