import React, { useState, useEffect } from 'react';
import { Droplets, Utensils, MapPin, RefreshCw, CheckCircle2, AlertTriangle } from 'lucide-react';
import { getFoodWaterPoints, updateFoodWaterPoint } from '../services/api';

export default function FoodWaterPoints() {
  const [points, setPoints] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchPoints();
  }, []);

  const fetchPoints = async () => {
    setLoading(true);
    try {
      const res = await getFoodWaterPoints();
      if (res.success) {
        setPoints(res.data || []);
      }
    } catch (err) {
      console.error('Fetch water points error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleToggleStatus = async (pointId, currentStatus) => {
    const nextStatus = currentStatus === 'AVAILABLE' ? 'LOW_SUPPLY' : currentStatus === 'LOW_SUPPLY' ? 'CLOSED' : 'AVAILABLE';
    try {
      await updateFoodWaterPoint(pointId, nextStatus, null);
      fetchPoints();
    } catch (err) {
      alert('Failed to update point status');
    }
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 clean-card p-6 bg-white border-slate-200">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-2xl bg-blue-50 text-blue-600 border border-blue-200">
            <Droplets className="w-7 h-7" />
          </div>
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
              Food Distribution & Water Hydration Points
            </h2>
            <p className="text-xs text-slate-500 mt-0.5 font-medium">
              Live capacity monitoring for water tanks, electrolyte stalls, and Annachhatra food pavilions
            </p>
          </div>
        </div>

        <button
          onClick={fetchPoints}
          className="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs flex items-center gap-2 transition-colors"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} /> Refresh Points
        </button>
      </div>

      {/* Grid of Food & Water Points */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {loading ? (
          <div className="col-span-full py-12 text-center text-slate-400 font-medium">
            Loading food & water stations...
          </div>
        ) : points.length === 0 ? (
          <div className="col-span-full py-12 text-center text-slate-400 font-medium">
            No water or food stations found.
          </div>
        ) : (
          points.map((p) => {
            const isWater = p.type === 'WATER';
            const isAvailable = p.status === 'AVAILABLE';
            const isLow = p.status === 'LOW_SUPPLY';

            return (
              <div key={p.point_id} className="clean-card p-5 space-y-3 relative">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <div className={`p-2 rounded-xl ${isWater ? 'bg-blue-50 text-blue-600' : 'bg-amber-50 text-amber-600'}`}>
                      {isWater ? <Droplets className="w-5 h-5" /> : <Utensils className="w-5 h-5" />}
                    </div>
                    <span className="font-mono text-xs font-bold text-slate-400">#{p.point_id}</span>
                  </div>

                  <span className={`px-2.5 py-0.5 rounded-full font-bold text-[10px] border ${
                    isAvailable
                      ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                      : isLow
                      ? 'bg-amber-50 text-amber-700 border-amber-200'
                      : 'bg-rose-50 text-rose-700 border-rose-200'
                  }`}>
                    {p.status}
                  </span>
                </div>

                <div>
                  <h4 className="font-extrabold text-slate-900 text-base">{p.name}</h4>
                  <p className="text-xs text-slate-500 flex items-center gap-1 mt-1 font-medium">
                    <MapPin className="w-3.5 h-3.5 text-orange-600" /> {p.location_name}
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-slate-50 border border-slate-100 flex items-center justify-between text-xs">
                  <span className="text-slate-500 font-medium">Capacity / Available:</span>
                  <span className="font-bold text-slate-900 text-sm">
                    {p.available_amount} / {p.capacity_liters_or_meals} {isWater ? 'Liters' : 'Meals'}
                  </span>
                </div>

                <button
                  onClick={() => handleToggleStatus(p.point_id, p.status)}
                  className="w-full py-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs transition-colors"
                >
                  Change Status ({p.status})
                </button>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
