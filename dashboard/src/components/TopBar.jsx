import React, { useState, useEffect } from 'react';
import { Search, Bell, Sparkles, Shield, RefreshCw } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { seedDemoData, getNotifications } from '../services/api';

export default function TopBar({ onGlobalSearch }) {
  const { admin } = useAuth();
  const [searchTerm, setSearchTerm] = useState('');
  const [notificationsCount, setNotificationsCount] = useState(3);
  const [seeding, setSeeding] = useState(false);
  const [seedMsg, setSeedMsg] = useState('');

  useEffect(() => {
    fetchNotificationCount();
    const interval = setInterval(fetchNotificationCount, 10000);
    return () => clearInterval(interval);
  }, []);

  const fetchNotificationCount = async () => {
    try {
      const res = await getNotifications();
      if (res.success && res.notifications) {
        const unread = res.notifications.filter(n => !n.is_read).length;
        setNotificationsCount(unread);
      }
    } catch (err) {
      // ignore
    }
  };

  const handleSearchChange = (e) => {
    setSearchTerm(e.target.value);
    if (onGlobalSearch) {
      onGlobalSearch(e.target.value);
    }
  };

  const handleSeedDemo = async () => {
    setSeeding(true);
    setSeedMsg('');
    try {
      const res = await seedDemoData();
      if (res.success) {
        setSeedMsg('Demo Data Seeded!');
        setTimeout(() => {
          window.location.reload();
        }, 1000);
      } else {
        setSeedMsg('Failed: ' + res.message);
      }
    } catch (err) {
      setSeedMsg('Error: ' + err.message);
    } finally {
      setSeeding(false);
    }
  };

  return (
    <header className="h-16 bg-white/75 backdrop-blur-md border-b border-slate-200/80 px-6 flex items-center justify-between sticky top-0 z-20 shadow-xs">
      {/* Live System Indicator */}
      <div className="flex items-center space-x-3">
        <div className="flex items-center space-x-2 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-700 font-semibold text-xs">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          <span>● LIVE — Wari Monitoring Active</span>
        </div>
        <span className="text-slate-500 text-xs hidden md:inline">| Pune - Pandharpur Route NH 965</span>
      </div>

      {/* Global Search Bar */}
      <div className="flex-1 max-w-md mx-6 hidden lg:block">
        <div className="relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search Varkari ID, Volunteer, SOS, Missing Person..."
            value={searchTerm}
            onChange={handleSearchChange}
            className="w-full pl-10 pr-4 py-1.5 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 text-xs focus:outline-none focus:border-orange-500 focus:bg-white transition-all placeholder:text-slate-400"
          />
        </div>
      </div>

      {/* Actions & Admin Profile */}
      <div className="flex items-center space-x-3">
        {/* Seed Demo Data Button */}
        <button
          onClick={handleSeedDemo}
          disabled={seeding}
          className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white font-semibold text-xs shadow-xs transition-all disabled:opacity-50"
          title="Seed PostgreSQL demo records for presentation"
        >
          {seeding ? (
            <RefreshCw className="w-3.5 h-3.5 animate-spin" />
          ) : (
            <Sparkles className="w-3.5 h-3.5" />
          )}
          <span>{seeding ? 'Seeding...' : 'Seed Demo Data'}</span>
        </button>

        {seedMsg && (
          <span className="text-xs text-orange-600 font-bold">{seedMsg}</span>
        )}

        {/* Notifications Icon */}
        <a
          href="/notifications"
          className="relative p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-600 transition-colors"
          title="Notifications Log"
        >
          <Bell className="w-4 h-4" />
          {notificationsCount > 0 && (
            <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-rose-600 text-white font-bold text-[10px] flex items-center justify-center border-2 border-white">
              {notificationsCount}
            </span>
          )}
        </a>

        {/* Admin Badge & Profile */}
        <div className="flex items-center space-x-2 pl-2 border-l border-slate-200">
          <div className="w-8 h-8 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-700 font-bold text-xs">
            <Shield className="w-4 h-4 text-orange-600" />
          </div>
          <div className="hidden sm:block text-left">
            <p className="text-xs font-bold text-slate-900 leading-tight">{admin?.full_name || 'Admin User'}</p>
            <p className="text-[10px] text-slate-500 font-medium">{admin?.role || 'Command Center'}</p>
          </div>
        </div>
      </div>
    </header>
  );
}
