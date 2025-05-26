import React from "react";
import { useState,useRef } from "react";
import { useNavigate } from "react-router-dom";
import "./Otp.css";

function InputOtp({length = 6 ,onChangeOTP}) {
    
    const [otp, setOtp] = useState(new Array(length).fill(""));
  const inputsRef = useRef([]);
  const [error, setError] = useState("");

  const navigate = useNavigate();

  const handleChange = (e, index) => {
    const val = e.value;
    if (/^[0-9]$/.test(val) || val === "") {
      const newOtp = [...otp];
      newOtp[index] = val;
      setOtp(newOtp);
      

      // Move to next input
      if (val && index < length - 1) {
        inputsRef.current[index + 1].focus();
      }

      if(onChangeOTP){
        onChangeOTP(newOtp.join(""));
      }
    }
  };

  const handleKeyDown = (e, index) => {
    if (e.key === "Backspace" && !otp[index] && index > 0) {
      inputsRef.current[index - 1].focus();
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const otpValue = otp.join("");

    if (otpValue.length === length) {
      console.log("OTP Submitted:", otpValue);

      const response = await fetch("/api/verify-otp", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ otp: otpValue }),
      });

      if (response.ok) {
        const data = await response.json();
        console.log("OTP Verification Successful:", data);

        //redirect
        navigate("/add-new-password");

      } else {
        setError("OTP Verification Failed. Please try again.");
        console.error("OTP Verification Failed");
      }
    } else {
        setError("Please enter a complete OTP");
      console.error("Please enter a complete OTP");
    }
  };


  return (
    <div className="otp-container">
      <h1>Enter OTP</h1>
      <form className="otp-form" onSubmit={handleSubmit}>
        {otp.map((data, index) => (
          <input
            key={index}
            type="text"
            maxLength="1"
            value={otp[index]}
            onChange={e => handleChange(e.target, index)}
            onKeyDown={e => handleKeyDown(e, index)}
            ref={el => (inputsRef.current[index] = el)}
            className="otp-input"
            style={{ width: "2em", textAlign: "center", marginRight: "0.5em" }}
          />
        ))}
        <button type="submit" className="otp-button">Verify</button>
      </form>

        {error && <p className="error-message">{error}</p>}
    </div>
  );
}

export default InputOtp;