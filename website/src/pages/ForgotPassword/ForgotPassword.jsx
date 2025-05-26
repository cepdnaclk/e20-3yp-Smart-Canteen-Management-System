import React from "react";
import validateEmail from "../../components/validateEmail.jsx";
import "./ForgotPassword.css";


function ForgotPassword() {

    const [email, setEmail] = React.useState("");
    const [error, setError] = React.useState("");
  const [success, setSuccess] = React.useState("");
  const [loading, setLoading] = React.useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();

        setError("");
    setSuccess("");

        // Validate email

        if (!email) {
            setError("Email is required");
            return;
        }
        if(!validateEmail(email)){
            setError("Please enter a valid email address");
            return;
        }
        setLoading(true);

            try{
                const response = await fetch("http://localhost:5173/sendresetemail", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({ email })
                });
                if(!response.ok) {
                    throw new Error("Failed to send reset email");
                }

                const data = await response.json();
                setSuccess("Password reset email sent successfully. Please check your inbox.");
                setEmail("");
            }catch (err) {
            console.error("Error sending password reset email:", err);
            setError("Failed to send password reset email. Please try again later.");
        } finally {
            setLoading(false);
        }
    };

    return (
  <div className="forgot-password-container">
    <h1>Send Password Reset Email</h1>
    <form className="forgot-password-form" onSubmit={handleSubmit}>
      <input
        type="email"
        placeholder="Enter your email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
        disabled={loading}
      />
      <button type="submit" disabled={loading}>
        {loading ? "Sending..." : "Send Reset Link"}
      </button>
    </form>
    {error && <p className="message error">{error}</p>}
    {success && <p className="message success">{success}</p>}
  </div>
);

}
export default ForgotPassword;