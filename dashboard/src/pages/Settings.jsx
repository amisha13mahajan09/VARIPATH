import React, { useState } from 'react';
import { Settings, Shield, Bell, Moon, Database } from 'lucide-react';

export default function SettingsPage() {
  const [pollingInterval, setPollingInterval] = useState('5');

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 clean-card p-6 bg-white border-slate-200">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-2xl bg-slate-100 text-slate-700 border border-slate-200">
            <Settings className="w-7 h-7" />
          </div>
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
              Command Center Settings
            </h2>
            <p className="text-xs text-slate-500 mt-0.5 font-medium">
              Telemetry polling intervals, notification thresholds, and API configurations
            </p>
          </div>
        </div>
      </div>

      <div className="clean-card p-6 space-y-4 max-w-xl text-xs bg-white border-slate-200">
        <div>
          <label className="block text-slate-700 font-semibold mb-1">Live Telemetry Polling Rate</label>
          <select
            value={pollingInterval}
            onChange={(e) => setPollingInterval(e.target.value)}
            className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 focus:outline-none focus:border-orange-500 focus:bg-white"
          >
            <option value="3">Every 3 seconds (High frequency)</option>
            <option value="5">Every 5 seconds (Recommended)</option>
            <option value="10">Every 10 seconds</option>
          </select>
        </div>

        <div>
          <label className="block text-slate-700 font-semibold mb-1">Backend Server API Endpoint</label>
          <input
            type="text"
            readOnly
            value="http://localhost:5001"
            className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 text-orange-600 font-mono font-bold"
          />
        </div>
      </div>
    </div>
  );
}
