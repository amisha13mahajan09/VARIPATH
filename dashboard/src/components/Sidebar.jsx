import React, { useState } from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  UserCheck,
  UserX,
  AlertTriangle,
  Stethoscope,
  Pill,
  Droplets,
  Map,
  Flame,
  Bell,
  BarChart3,
  ShieldCheck,
  Settings,
  LogOut,
  ChevronLeft,
  ChevronRight,
  Radio
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export default function Sidebar() {
  const [collapsed, setCollapsed] = useState(false);
  const { logout } = useAuth();

  const navItems = [
    { path: '/', label: 'Dashboard Home', icon: LayoutDashboard },
    { path: '/varkaris', label: 'Varkaris Roster', icon: Users },
    { path: '/volunteers', label: 'Volunteers Hub', icon: UserCheck },
    { path: '/sos', label: 'SOS / Emergencies', icon: AlertTriangle, badge: 'LIVE' },
    { path: '/missing-persons', label: 'Missing Persons', icon: UserX },
    { path: '/medical-camps', label: 'Medical Camps', icon: Stethoscope },
    { path: '/medicines', label: 'Medicine Stock', icon: Pill },
    { path: '/food-water', label: 'Food & Water Points', icon: Droplets },
    { path: '/live-map', label: 'Wari Route Map', icon: Map, badge: 'MAP' },
    { path: '/weather-risk', label: 'Heat & Weather Risk', icon: Flame },
    { path: '/notifications', label: 'Notifications', icon: Bell },
    { path: '/reports', label: 'Reports & Analytics', icon: BarChart3 },
    { path: '/admin-mgmt', label: 'Admin Management', icon: ShieldCheck },
    { path: '/settings', label: 'System Settings', icon: Settings },
  ];

  return (
    <aside
      className={`fixed left-0 top-0 bottom-0 z-30 flex flex-col bg-white border-r border-slate-200 transition-all duration-300 shadow-sm ${
        collapsed ? 'w-20' : 'w-64'
      }`}
    >
      {/* Header & Branding */}
      <div className="h-16 px-4 flex items-center justify-between border-b border-slate-200">
        {!collapsed && (
          <div className="flex items-center space-x-3 overflow-hidden">
            <div className="w-9 h-9 rounded-xl bg-orange-600 flex items-center justify-center text-white font-bold text-lg shadow-sm">
              🚩
            </div>
            <div>
              <h1 className="font-extrabold text-slate-900 text-base tracking-tight leading-none font-marathi">
                वारीपथ <span className="text-orange-600 font-sans text-xs">Command</span>
              </h1>
              <span className="text-[11px] text-slate-500 font-medium tracking-wide flex items-center gap-1 mt-0.5">
                <Radio className="w-2.5 h-2.5 text-emerald-500 animate-pulse" /> Wari 2026 Live
              </span>
            </div>
          </div>
        )}

        {collapsed && (
          <div className="w-9 h-9 mx-auto rounded-xl bg-orange-600 flex items-center justify-center text-white text-lg">
            🚩
          </div>
        )}

        <button
          onClick={() => setCollapsed(!collapsed)}
          className="p-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-600 transition-colors"
          title={collapsed ? 'Expand Sidebar' : 'Collapse Sidebar'}
        >
          {collapsed ? <ChevronRight className="w-4 h-4" /> : <ChevronLeft className="w-4 h-4" />}
        </button>
      </div>

      {/* Navigation List */}
      <div className="flex-1 overflow-y-auto py-3 px-3 space-y-1">
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2.5 rounded-xl font-medium text-sm transition-all duration-150 ${
                  isActive
                    ? 'bg-orange-50 text-orange-600 font-bold border border-orange-200/80 shadow-xs'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`
              }
            >
              <Icon className="w-4 h-4 flex-shrink-0" />
              {!collapsed && (
                <span className="truncate flex-1 text-xs">{item.label}</span>
              )}
              {!collapsed && item.badge && (
                <span
                  className={`text-[10px] px-1.5 py-0.5 rounded font-bold ${
                    item.badge === 'LIVE'
                      ? 'bg-rose-100 text-rose-700 border border-rose-200 animate-pulse'
                      : 'bg-blue-100 text-blue-700 border border-blue-200'
                  }`}
                >
                  {item.badge}
                </span>
              )}
            </NavLink>
          );
        })}
      </div>

      {/* Footer / Logout */}
      <div className="p-3 border-t border-slate-200">
        <button
          onClick={logout}
          className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-semibold text-rose-600 hover:bg-rose-50 transition-colors ${
            collapsed ? 'justify-center' : ''
          }`}
          title="Logout from Command Center"
        >
          <LogOut className="w-4 h-4 flex-shrink-0" />
          {!collapsed && <span>Logout</span>}
        </button>
      </div>
    </aside>
  );
}
