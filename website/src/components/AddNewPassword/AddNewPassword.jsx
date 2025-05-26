import React, { useState } from "react";
import validatePassword from "../validatePassword.jsx";
import { useNavigate as navigator } from "react-router-dom";

import "./AddNewPassword.css";

function AddNewPassword() {
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");

    const [error,setError] = useState("");
    const [success,setSuccess] = useState("");

    const navigate = navigator();


    const handleSubmit = async (e) => {
    e.preventDefault();

    setError("");
    setSuccess("");
        
    //validate password
    const validation = validatePassword(password);

    if(!validation.valid){
        setError(validation.errors.join(", "));
        return;
    }

    if(password!== confirmPassword){
        setError("Passwords do not match");

        return;
    }

    try{
        const response = await fetch("/api/add-new-password", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({ password }),
        });
        if (!response.ok) {
            const errorData = await response.json();
            setError(errorData.message || "Failed to add new password");
            return;
        }
        setSuccess("Password changed successfully");
        setPassword("");
        setConfirmPassword("");

        navigate("/login"); // Redirect to login page

    }catch (error) {
        console.error("Error adding new password:", error);
        setError("An error occurred while changing the new password");
        return;
    }

    };
  return (
    <div className="add-new-password">
      <h1>Add New Password</h1>
      <form onSubmit={handleSubmit} noValidate>
        <label htmlFor="new-password">New Password:</label>
        <input 
        type="password" 
        id="new-password" 
        name="new-password" 
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
        autoComplete="new-password" />

        <label htmlFor="confirm-password">Confirm Password:</label>
        <input 
        type="password" 
        id="confirm-password" 
        name="confirm-password" 
        value={confirmPassword}
        onChange={(e) => setConfirmPassword(e.target.value)}
        required
        autoComplete="new-password" />

        <button type="submit" disabled={!password || !confirmPassword }>Submit</button>
      </form>
        {error && <p className="error">{error}</p>}
        {success && <p className="success">{success}</p>}
    </div>
  );
}

export default AddNewPassword;