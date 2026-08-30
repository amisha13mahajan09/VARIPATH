import React, { useState, useEffect } from 'react';
import { Flame, Sun, Droplets, AlertTriangle, ShieldCheck, Thermometer, RefreshCw } from 'lucide-react';
import { getWeatherRiskZones } from '../services/api';

export default function WeatherRisk() {
  const [zones, setZones] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchWeatherRisk();
  }, []);

  const fetchWeatherRisk = async () => {
    setLoading(true);
    try {
      const res = await getWeatherRiskZones();
      if (res.success) {
        setZones(res.zones || []);
      }
    } catch (err) {
      console.error('Fetch weather risk error:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 clean-card p-6 bg-white border-slate-200">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-2xl bg-rose-50 text-rose-600 border border-rose-200">
            <Flame className="w-7 h-7" />
          </div>
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
              Heat & Weather Risk Monitoring
            </h2>
            <p className="text-xs text-slate-500 mt-0.5 font-medium">
              Live weather telemetry, temperature tracking, heat-stroke alerts, and hydration advisories along the Wari route
            </p>
          </div>
        </div>

        <button
          onClick={fetchWeatherRisk}
          className="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs flex items-center gap-2 transition-colors"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} /> Refresh Advisories
        </button>
      </div>

      {/* Risk Zones Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {loading ? (
          <div className="col-span-full py-12 text-center text-slate-400 font-medium">
            Loading weather telemetry...
          </div>
        ) : (
          zones.map((zone) => {
            const isCritical = zone.risk_level === 'Critical';
            const isHigh = zone.risk_level === 'High Risk';

            return (
              <div key={zone.id} className="clean-card p-5 space-y-3 relative">
                <div className="flex items-start justify-between">
                  <div className="flex items-center space-x-3">
                    <div className={`p-2.5 rounded-xl ${isCritical ? 'bg-rose-50 text-rose-600 border border-rose-200' : isHigh ? 'bg-orange-50 text-orange-600 border border-orange-200' : 'bg-emerald-50 text-emerald-600 border border-emerald-200'}`}>
                      <Thermometer className="w-6 h-6" />
                    </div>
                    <div>
                      <span className="font-mono text-[11px] font-bold text-slate-400">#{zone.id}</span>
                      <h4 className="font-extrabold text-slate-900 text-base">{zone.location}</h4>
                    </div>
                  </div>

                  <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold border ${
                    isCritical
                      ? 'bg-rose-50 text-rose-700 border-rose-200'
                      : isHigh
                      ? 'bg-orange-50 text-orange-700 border-orange-200'
                      : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                  }`}>
                    {zone.risk_level}
                  </span>
                </div>

                <div className="grid grid-cols-3 gap-2 text-center text-xs my-2">
                  <div className="p-2 rounded-xl bg-slate-50 border border-slate-100">
                    <p className="text-[10px] text-slate-400 uppercase font-semibold">Temperature</p>
                    <p className="font-extrabold text-slate-900 text-base mt-0.5">{zone.temperature}°C</p>
                  </div>
                  <div className="p-2 rounded-xl bg-slate-50 border border-slate-100">
                    <p className="text-[10px] text-slate-400 uppercase font-semibold">Humidity</p>
                    <p className="font-extrabold text-cyan-700 text-base mt-0.5">{zone.humidity}%</p>
                  </div>
                  <div className="p-2 rounded-xl bg-slate-50 border border-slate-100">
                    <p className="text-[10px] text-slate-400 uppercase font-semibold">Heat Index</p>
                    <p className="font-extrabold text-amber-700 text-base mt-0.5">{zone.heat_index}°C</p>
                  </div>
                </div>

                <div className="p-3 rounded-xl bg-slate-50 border border-slate-100 text-xs space-y-1">
                  <p className="font-semibold text-orange-700 font-marathi">मराठी सल्ला: {zone.advisory_marathi}</p>
                  <p className="text-slate-600">English Advisory: "{zone.advisory_english}"</p>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
