import React, { createContext, useContext, useState, useEffect } from 'react';
import { loginAdmin } from '../services/api';

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [admin, setAdmin] = useState(() => {
    const saved = localStorage.getItem('varipath_admin_user');
    return saved ? JSON.parse(saved) : { username: 'admin', full_name: 'Command Center Admin', role: 'SUPER_ADMIN' };
  });

  const [isAuthenticated, setIsAuthenticated] = useState(() => {
    return true; // Default logged in for hackathon demo ease, can log out anytime
  });

  const login = async (username, password) => {
    try {
      const res = await loginAdmin(username, password);
      if (res.success) {
        setAdmin(res.admin);
        setIsAuthenticated(true);
        localStorage.setItem('varipath_admin_user', JSON.stringify(res.admin));
        localStorage.setItem('varipath_admin_token', res.token);
        return { success: true };
      }
      return { success: false, message: res.message };
    } catch (err) {
      // Fallback demo auth
      if (username === 'admin' && (password === 'admin123' || password === 'admin')) {
        const demoUser = { username: 'admin', full_name: 'VariPath Command Center Admin', role: 'SUPER_ADMIN' };
        setAdmin(demoUser);
        setIsAuthenticated(true);
        localStorage.setItem('varipath_admin_user', JSON.stringify(demoUser));
        return { success: true };
      }
      return { success: false, message: err.message || 'Login failed' };
    }
  };

  const logout = () => {
    setAdmin(null);
    setIsAuthenticated(false);
    localStorage.removeItem('varipath_admin_user');
    localStorage.removeItem('varipath_admin_token');
  };

  return (
    <AuthContext.Provider value={{ admin, isAuthenticated, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
