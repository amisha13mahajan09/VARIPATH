import React, { useState, useEffect } from 'react';
import { Users, Search, Filter, Eye, Phone, HeartPulse, MapPin, RefreshCw } from 'lucide-react';
import VarkariDetailModal from '../components/VarkariDetailModal';
import { getVarkaris } from '../services/api';

export default function VarkariManagement() {
  const [varkaris, setVarkaris] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [selectedVarkari, setSelectedVarkari] = useState(null);
  const [modalOpen, setModalOpen] = useState(false);

  useEffect(() => {
    fetchVarkarisList();
  }, [statusFilter]);

  const fetchVarkarisList = async () => {
    setLoading(true);
    try {
      const res = await getVarkaris(searchTerm, statusFilter);
      if (res.success) {
        setVarkaris(res.varkaris || []);
      }
    } catch (err) {
      console.error('Fetch varkaris error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSearchSubmit = (e) => {
    e.preventDefault();
    fetchVarkarisList();
  };

  const filteredVarkaris = varkaris.filter((v) => {
    const term = searchTerm.toLowerCase();
    return (
      (v.name || '').toLowerCase().includes(term) ||
      (v.varkari_id || '').toLowerCase().includes(term) ||
      (v.phone || '').includes(term)
    );
  });

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 clean-card p-6 bg-white border-slate-200">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-2xl bg-amber-50 text-amber-600 border border-amber-200">
            <Users className="w-7 h-7" />
          </div>
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
              Varkari Roster & Directory
            </h2>
            <p className="text-xs text-slate-500 mt-0.5 font-medium">
              Comprehensive list of all registered pilgrims with live GPS and medical profiles
            </p>
          </div>
        </div>

        <button
          onClick={fetchVarkarisList}
          className="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs flex items-center gap-2 transition-colors"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} /> Refresh Roster
        </button>
      </div>

      {/* Filter and Search Bar */}
      <div className="clean-card p-4 flex flex-col md:flex-row items-center justify-between gap-4">
        <form onSubmit={handleSearchSubmit} className="relative w-full md:w-80">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search Varkari Name, ID (VK100001), Phone..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 text-xs focus:outline-none focus:border-orange-500 focus:bg-white"
          />
        </form>

        <div className="flex items-center space-x-2 overflow-x-auto w-full md:w-auto">
          <span className="text-xs font-semibold text-slate-500 flex items-center gap-1">
            <Filter className="w-3.5 h-3.5" /> Status:
          </span>
          {['ALL', 'ACTIVE', 'EMERGENCY', 'MISSING', 'SAFE'].map((st) => (
            <button
              key={st}
              onClick={() => setStatusFilter(st)}
              className={`px-3 py-1.5 rounded-xl font-bold text-xs transition-all ${
                statusFilter === st
                  ? 'bg-orange-600 text-white shadow-xs'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              {st}
            </button>
          ))}
        </div>
      </div>

      {/* Varkaris Table */}
      <div className="clean-card overflow-hidden border border-slate-200">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-700">
            <thead className="bg-slate-50 text-slate-500 uppercase font-bold border-b border-slate-200">
              <tr>
                <th className="py-3.5 px-4">Varkari ID</th>
                <th className="py-3.5 px-4">Name</th>
                <th className="py-3.5 px-4">Age / Gender</th>
                <th className="py-3.5 px-4">Mobile</th>
                <th className="py-3.5 px-4">Health Profile</th>
                <th className="py-3.5 px-4">Current GPS</th>
                <th className="py-3.5 px-4">Status</th>
                <th className="py-3.5 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={8} className="py-8 text-center text-slate-400 font-medium">
                    Loading Varkaris database...
                  </td>
                </tr>
              ) : filteredVarkaris.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-8 text-center text-slate-400 font-medium">
                    No registered Varkaris found matching criteria.
                  </td>
                </tr>
              ) : (
                filteredVarkaris.map((v) => (
                  <tr key={v.varkari_id} className="hover:bg-slate-50 transition-colors">
                    <td className="py-3.5 px-4 font-mono font-bold text-orange-600">{v.varkari_id}</td>
                    <td className="py-3.5 px-4 font-bold text-slate-900">{v.name || `${v.first_name} ${v.last_name}`}</td>
                    <td className="py-3.5 px-4">{v.age} yrs • {v.gender}</td>
                    <td className="py-3.5 px-4 font-mono text-slate-600">{v.phone}</td>
                    <td className="py-3.5 px-4 max-w-xs truncate text-rose-600 font-medium">
                      <span className="flex items-center gap-1">
                        <HeartPulse className="w-3.5 h-3.5 text-rose-500 flex-shrink-0" />
                        {Array.isArray(v.health_conditions) ? v.health_conditions.join(', ') : v.health_conditions || 'Healthy'}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 font-mono text-slate-500 text-[11px]">
                      {v.latitude ? `${v.latitude.toFixed(3)}, ${v.longitude?.toFixed(3)}` : 'On Route'}
                    </td>
                    <td className="py-3.5 px-4">
                      <span className={`px-2.5 py-0.5 rounded-full font-bold text-[10px] border ${
                        v.status === 'EMERGENCY'
                          ? 'bg-rose-50 text-rose-700 border-rose-200'
                          : v.status === 'MISSING'
                          ? 'bg-amber-50 text-amber-700 border-amber-200'
                          : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                      }`}>
                        {v.status || 'SAFE'}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-right">
                      <button
                        onClick={() => {
                          setSelectedVarkari(v);
                          setModalOpen(true);
                        }}
                        className="px-2.5 py-1 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs inline-flex items-center gap-1 transition-colors"
                      >
                        <Eye className="w-3.5 h-3.5" /> Profile
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <VarkariDetailModal
        varkari={selectedVarkari}
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
      />
    </div>
  );
}
