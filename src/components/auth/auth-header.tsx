import React from 'react';
import asclepiusLogo from '../../assets/asclepiusLogo.png';


export const AuthHeader = () => {
  return (
    <div className="auth-header">
      <img src={asclepiusLogo} alt="Asclepius Logo" className="auth-logo" />
      <h1>Welcome to Asclepius</h1>
      <p>Sign in to your account</p>
    </div>
  );
};