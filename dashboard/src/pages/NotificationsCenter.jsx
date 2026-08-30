import React, { useState, useEffect } from 'react';
import { Bell, CheckCircle2, ShieldAlert, AlertTriangle, RefreshCw } from 'lucide-react';
import { getNotifications, markNotificationsRead } from '../services/api';

export default function NotificationsCenter() {
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchNotificationsList();
  }, []);

  const fetchNotificationsList = async () => {
    setLoading(true);
    try {
      const res = await getNotifications();
      if (res.success) {
        setNotifications(res.notifications || []);
      }
    } catch (err) {
      console.error('Fetch notifications error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleMarkAllRead = async () => {
    try {
      await markNotificationsRead();
      fetchNotificationsList();
    } catch (err) {
      alert('Failed to mark notifications read');
    }
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 clean-card p-6 bg-white border-slate-200">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-2xl bg-amber-50 text-amber-600 border border-amber-200">
            <Bell className="w-7 h-7" />
          </div>
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
              Command Center Notifications & System Log
            </h2>
            <p className="text-xs text-slate-500 mt-0.5 font-medium">
              Live broadcast alerts for SOS requests, missing persons, low medicine stock, and heat warnings
            </p>
          </div>
        </div>

        <div className="flex items-center space-x-2">
          <button
            onClick={handleMarkAllRead}
            className="px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs flex items-center gap-1.5 transition-colors"
          >
            <CheckCircle2 className="w-3.5 h-3.5" /> Mark All Read
          </button>
          <button
            onClick={fetchNotificationsList}
            className="p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 transition-colors"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Notifications List */}
      <div className="space-y-3">
        {loading ? (
          <div className="clean-card p-8 text-center text-slate-400 text-xs font-medium">
            Loading notifications history...
          </div>
        ) : notifications.length === 0 ? (
          <div className="clean-card p-8 text-center text-slate-400 text-xs font-medium">
            No system notifications present.
          </div>
        ) : (
          notifications.map((n) => {
            const isCritical = n.severity === 'CRITICAL' || n.category === 'SOS';
            const isHigh = n.severity === 'HIGH' || n.category === 'STOCK';

            return (
              <div
                key={n.id}
                className={`clean-card p-4 flex items-start justify-between gap-4 transition-all ${
                  !n.is_read ? 'border-amber-300 bg-amber-50/40' : 'bg-white'
                }`}
              >
                <div className="flex items-start space-x-3">
                  <div className={`p-2 rounded-xl mt-0.5 ${isCritical ? 'bg-rose-100 text-rose-700' : isHigh ? 'bg-amber-100 text-amber-700' : 'bg-blue-100 text-blue-700'}`}>
                    <Bell className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="flex items-center space-x-2">
                      <h4 className="font-bold text-slate-900 text-sm">{n.title}</h4>
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${
                        isCritical ? 'bg-rose-50 text-rose-700 border-rose-200' : 'bg-amber-50 text-amber-700 border-amber-200'
                      }`}>
                        {n.category}
                      </span>
                    </div>
                    <p className="text-xs text-slate-600 mt-1">{n.message}</p>
                    <p className="text-[10px] text-slate-400 mt-1">
                      {n.created_at ? new Date(n.created_at).toLocaleString() : 'Just now'}
                    </p>
                  </div>
                </div>

                {!n.is_read && (
                  <span className="w-2.5 h-2.5 rounded-full bg-amber-500 flex-shrink-0 mt-1.5" />
                )}
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
