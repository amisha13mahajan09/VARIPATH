import React from 'react';
import { X, User, Phone, MapPin, HeartPulse, Activity, ShieldAlert, Calendar, Droplets } from 'lucide-react';

export default function VarkariDetailModal({ varkari, isOpen, onClose }) {
  if (!isOpen || !varkari) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm animate-fade-in">
      <div className="glass-panel w-full max-w-xl p-6 relative border-slate-700 shadow-2xl">
        <button
          onClick={onClose}
          className="absolute right-4 top-4 p-1.5 rounded-lg bg-slate-800 text-slate-400 hover:text-white"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="flex items-center space-x-4 mb-5 pb-4 border-b border-slate-800">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-amber-500/20 to-orange-500/20 border border-orange-500/30 flex items-center justify-center text-orange-400 font-bold text-2xl">
            🚩
          </div>
          <div>
            <div className="flex items-center space-x-2">
              <span className="font-mono text-xs font-bold text-amber-400 bg-amber-500/10 px-2 py-0.5 rounded-md border border-amber-500/20">
                {varkari.varkari_id || varkari.username}
              </span>
              <span className={`text-[10px] font-extrabold px-2 py-0.5 rounded-full border ${
                varkari.status === 'EMERGENCY'
                  ? 'bg-red-500/20 text-red-400 border-red-500/30 animate-pulse'
                  : 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30'
              }`}>
                {varkari.status || 'SAFE'}
              </span>
            </div>
            <h3 className="text-xl font-extrabold text-white mt-0.5">{varkari.name || `${varkari.first_name} ${varkari.last_name}`}</h3>
          </div>
        </div>

        {/* Profile Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm mb-5">
          <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800">
            <p className="text-xs text-slate-400 font-medium">Personal Details</p>
            <p className="text-white font-semibold mt-1">{varkari.age} yrs • {varkari.gender}</p>
            <p className="text-xs text-slate-300 flex items-center gap-1 mt-1">
              <Droplets className="w-3.5 h-3.5 text-red-400" /> Blood Group: <strong className="text-white">{varkari.blood_group || 'O+'}</strong>
            </p>
          </div>

          <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800">
            <p className="text-xs text-slate-400 font-medium">Contact Details</p>
            <p className="text-amber-400 font-semibold mt-1">📞 {varkari.phone}</p>
            <p className="text-xs text-slate-300 mt-1">Emergency: <strong className="text-red-400">{varkari.emergency_contact}</strong></p>
          </div>

          <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800 col-span-1 sm:col-span-2">
            <p className="text-xs text-slate-400 font-medium flex items-center gap-1.5 text-rose-400">
              <HeartPulse className="w-4 h-4" /> Health Conditions & Medical Profile
            </p>
            <p className="text-slate-200 text-sm mt-1 font-medium">
              {Array.isArray(varkari.health_conditions)
                ? varkari.health_conditions.join(', ')
                : varkari.health_conditions || 'None reported'}
            </p>
          </div>

          <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800 col-span-1 sm:col-span-2">
            <p className="text-xs text-slate-400 font-medium flex items-center gap-1.5 text-orange-400">
              <MapPin className="w-4 h-4" /> Current Wari Location & Tracking
            </p>
            <p className="text-slate-200 font-mono text-xs mt-1">
              GPS: {varkari.latitude ? `${varkari.latitude.toFixed(4)}, ${varkari.longitude?.toFixed(4)}` : 'Location Shared on NH 965 Route'}
            </p>
          </div>
        </div>

        <div className="flex justify-end pt-3 border-t border-slate-800">
          <button
            onClick={onClose}
            className="px-5 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-semibold text-xs"
          >
            Close Profile
          </button>
        </div>
      </div>
    </div>
  );
}
