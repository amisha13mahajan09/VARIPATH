import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Lock, User, Radio, ArrowRight, ShieldCheck } from 'lucide-react';

export default function Login() {
  const [username, setUsername] = useState('admin');
  const [password, setPassword] = useState('admin123');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const res = await login(username, password);
      if (res.success) {
        navigate('/');
      } else {
        setError(res.message || 'Invalid username or password');
      }
    } catch (err) {
      setError('Connection error to backend server');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4">
      <div className="w-full max-w-md space-y-6">
        {/* Branding Header */}
        <div className="text-center space-y-2">
          <div className="w-16 h-16 rounded-2xl bg-orange-600 text-white text-3xl font-extrabold flex items-center justify-center mx-auto shadow-md">
            🚩
          </div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tight font-marathi">
            वारीपथ (VariPath)
          </h1>
          <p className="text-xs text-slate-500 font-medium">
            Organizer & Emergency Command Center Dashboard
          </p>
        </div>

        {/* Clean Login Card */}
        <div className="clean-card p-8 bg-white border-slate-200 shadow-sm space-y-6">
          <div className="border-b border-slate-100 pb-4 text-center">
            <h2 className="text-lg font-bold text-slate-900">Admin Sign In</h2>
            <p className="text-xs text-slate-500 mt-0.5">Enter organizer credentials to access telemetry</p>
          </div>

          {error && (
            <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-semibold text-center">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4 text-xs">
            <div>
              <label className="block text-slate-700 font-semibold mb-1">Username</label>
              <div className="relative">
                <User className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  required
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder="Enter admin username"
                  className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 font-medium focus:outline-none focus:border-orange-500 focus:bg-white transition-all"
                />
              </div>
            </div>

            <div>
              <label className="block text-slate-700 font-semibold mb-1">Password</label>
              <div className="relative">
                <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter password"
                  className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 font-medium focus:outline-none focus:border-orange-500 focus:bg-white transition-all"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 rounded-xl bg-orange-600 hover:bg-orange-700 text-white font-bold text-xs shadow-xs transition-all flex items-center justify-center gap-2 disabled:opacity-50"
            >
              <span>{loading ? 'Authenticating...' : 'Sign In to Dashboard'}</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </form>

          {/* Quick Demo Credentials Info */}
          <div className="p-3 rounded-xl bg-slate-50 border border-slate-200 text-center space-y-1">
            <p className="text-[11px] font-bold text-slate-700">Default Demo Credentials:</p>
            <p className="text-[11px] text-slate-500 font-mono">User: <strong className="text-orange-600">admin</strong> • Pass: <strong className="text-orange-600">admin123</strong></p>
          </div>
        </div>
      </div>
    </div>
  );
}
