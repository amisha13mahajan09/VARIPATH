import React, { useState, useEffect } from 'react';
import { Stethoscope, MapPin, Phone, User, Clock, AlertTriangle, ShieldCheck, RefreshCw } from 'lucide-react';
import { getMedicalCamps } from '../services/api';

export default function MedicalCamps() {
  const [camps, setCamps] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchCampsList();
  }, []);

  const fetchCampsList = async () => {
    setLoading(true);
    try {
      const res = await getMedicalCamps();
      if (res.success) {
        setCamps(res.data || []);
      }
    } catch (err) {
      console.error('Fetch camps error:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 clean-card p-6 bg-white border-slate-200">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-2xl bg-blue-50 text-blue-600 border border-blue-200">
            <Stethoscope className="w-7 h-7" />
          </div>
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
              Medical Camps Directory & Emergency Posts
            </h2>
            <p className="text-xs text-slate-500 mt-0.5 font-medium">
              Live status, emergency capabilities, doctor contacts, and patient traffic along Wari route
            </p>
          </div>
        </div>

        <button
          onClick={fetchCampsList}
          className="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs flex items-center gap-2 transition-colors"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} /> Refresh Directory
        </button>
      </div>

      {/* Medical Camps Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {loading ? (
          <div className="col-span-full py-12 text-center text-slate-400 font-medium">
            Loading medical camps...
          </div>
        ) : camps.length === 0 ? (
          <div className="col-span-full py-12 text-center text-slate-400 font-medium">
            No medical camps found in database.
          </div>
        ) : (
          camps.map((camp) => (
            <div key={camp.camp_id} className="clean-card p-5 space-y-3 relative">
              <div className="flex items-start justify-between">
                <div className="flex items-center space-x-3">
                  <div className="p-2.5 rounded-xl bg-emerald-50 text-emerald-600 border border-emerald-200">
                    <Stethoscope className="w-5 h-5" />
                  </div>
                  <div>
                    <span className="font-mono text-[11px] font-bold text-slate-400">#{camp.camp_id}</span>
                    <h4 className="font-extrabold text-slate-900 text-base">{camp.name}</h4>
                  </div>
                </div>

                <span className="px-2.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 text-[10px] font-bold">
                  {camp.status || 'ACTIVE'}
                </span>
              </div>

              <div className="space-y-1.5 text-xs text-slate-600">
                <p className="flex items-center gap-2">
                  <MapPin className="w-3.5 h-3.5 text-orange-600 flex-shrink-0" />
                  <span>Location: <strong className="text-slate-900">{camp.location_name}</strong></span>
                </p>
                <p className="flex items-center gap-2">
                  <User className="w-3.5 h-3.5 text-blue-600 flex-shrink-0" />
                  <span>Doctor in Charge: <strong className="text-slate-900">{camp.doctor_in_charge || 'Dr. Medical Team'}</strong></span>
                </p>
                <p className="flex items-center gap-2">
                  <Phone className="w-3.5 h-3.5 text-emerald-600 flex-shrink-0" />
                  <span>Emergency Phone: <strong className="text-slate-900 font-mono">{camp.contact_phone || '+91 98230 55667'}</strong></span>
                </p>
              </div>

              {/* Stats Footer */}
              <div className="grid grid-cols-3 gap-2 pt-3 border-t border-slate-100 text-center text-xs">
                <div className="p-2 rounded-xl bg-slate-50 border border-slate-100">
                  <p className="text-[10px] text-slate-400 uppercase font-semibold">Capability</p>
                  <p className="font-bold text-slate-900 mt-0.5">{camp.emergency_capability || 'High'}</p>
                </div>
                <div className="p-2 rounded-xl bg-slate-50 border border-slate-100">
                  <p className="text-[10px] text-slate-400 uppercase font-semibold">Operating Hours</p>
                  <p className="font-bold text-emerald-700 mt-0.5">{camp.operating_hours || '24/7'}</p>
                </div>
                <div className="p-2 rounded-xl bg-slate-50 border border-slate-100">
                  <p className="text-[10px] text-slate-400 uppercase font-semibold">Patients Today</p>
                  <p className="font-bold text-blue-700 mt-0.5">{camp.patient_count || 42}</p>
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
