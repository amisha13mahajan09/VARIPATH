import React, { useState } from 'react';
import { ShieldCheck, Sparkles, RefreshCw, Key, UserPlus } from 'lucide-react';
import { seedDemoData } from '../services/api';

export default function AdminManagement() {
  const [seeding, setSeeding] = useState(false);
  const [statusMsg, setStatusMsg] = useState('');

  const handleSeed = async () => {
    setSeeding(true);
    setStatusMsg('');
    try {
      const res = await seedDemoData();
      if (res.success) {
        setStatusMsg('PostgreSQL database seeded successfully with realistic demo data!');
      } else {
        setStatusMsg('Seeding error: ' + res.message);
      }
    } catch (err) {
      setStatusMsg('Seeding error: ' + err.message);
    } finally {
      setSeeding(false);
    }
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 clean-card p-6 bg-white border-slate-200">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-2xl bg-slate-100 text-amber-600 border border-slate-200">
            <ShieldCheck className="w-7 h-7" />
          </div>
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
              Admin & System Roles Management
            </h2>
            <p className="text-xs text-slate-500 mt-0.5 font-medium">
              Access control, database seed utility, and system logs
            </p>
          </div>
        </div>
      </div>

      {/* Demo Seed Utility Box */}
      <div className="clean-card p-6 border-orange-200 bg-orange-50/30 space-y-4">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-xl bg-orange-100 text-orange-600">
            <Sparkles className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-slate-900">Hackathon Presentation Demo Seeder</h3>
            <p className="text-xs text-slate-600">Populates PostgreSQL DB with realistic Varkaris, Volunteers, active SOS, missing persons, medical camps, and water points.</p>
          </div>
        </div>

        {statusMsg && (
          <div className="p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-semibold">
            {statusMsg}
          </div>
        )}

        <button
          onClick={handleSeed}
          disabled={seeding}
          className="px-6 py-2.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white font-bold text-xs shadow-xs transition-all flex items-center gap-2 disabled:opacity-50"
        >
          <RefreshCw className={`w-4 h-4 ${seeding ? 'animate-spin' : ''}`} />
          {seeding ? 'Seeding PostgreSQL Database...' : 'Run Demo Data Seeder Now'}
        </button>
      </div>
    </div>
  );
}
