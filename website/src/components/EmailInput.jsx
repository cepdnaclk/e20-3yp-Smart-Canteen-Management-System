import React from "react";


function EmailInput({ value, onChange, error }) {
  return (
    <div className="form-group">
      <label htmlFor="email">Email</label>
      <input
        type="email"
        id="email"
        name="email"
        value={value}
        onChange={onChange}
        className={`form-control ${error ? 'is-invalid' : ''}`}
        placeholder="Enter your email"
      />
      {error && <div className="invalid-feedback">{error}</div>}
    </div>
  );
}

export default EmailInput;