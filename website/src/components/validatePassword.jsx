import React from "react";

function validatePassword(password) {
  const errors = [];

  if (typeof password !== "string") {
    return {
      valid: false,
      errors: ["Password must be a string."],
    };
  }

  if (password.length < 8) {
    errors.push("Password must be at least 8 characters long.");
  }

  if (!/[A-Z]/.test(password)) {
    errors.push("Password must contain at least one uppercase letter.");
  }

  if (!/[a-z]/.test(password)) {
    errors.push("Password must contain at least one lowercase letter.");
  }

  if (!/[0-9]/.test(password)) {
    errors.push("Password must contain at least one digit.");
  }

  if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    errors.push("Password must contain at least one special character.");
  }

  if (/\s/.test(password)) {
    errors.push("Password must not contain spaces.");
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

export default validatePassword;
