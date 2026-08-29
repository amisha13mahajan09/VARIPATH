import React, { useState, useEffect } from 'react';
import { AlertTriangle, Filter, CheckCircle2, UserCheck, ShieldAlert, RefreshCw, Search } from 'lucide-react';
import SOSCard from '../components/SOSCard';
import AssignVolunteerModal from '../components/AssignVolunteerModal';
import { getAllAssistanceRequests, updateSosStatus } from '../services/api';

export default function SOSMonitoring() {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState('ALL');
  const [searchTerm, setSearchTerm] = useState('');
  const [assignModalOpen, setAssignModalOpen] = useState(false);
  const [targetSos, setTargetSos] = useState(null);

  useEffect(() => {
    fetchRequests();
    const interval = setInterval(fetchRequests, 5000);
    return () => clearInterval(interval);
  }, []);

  const fetchRequests = async () => {
    try {
      const res = await getAllAssistanceRequests();
      if (res.success) {
        setRequests(res.data || []);
      }
    } catch (err) {
      console.error('Fetch SOS error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenAssign = (sos) => {
    setTargetSos(sos);
    setAssignModalOpen(true);
  };

  const handleResolveSos = async (id) => {
    try {
      await updateSosStatus(id, 'RESOLVED');
      fetchRequests();
    } catch (err) {
      alert('Failed to resolve SOS');
    }
  };

  const filteredRequests = requests.filter((req) => {
    const matchesStatus =
      filterStatus === 'ALL'
        ? true
        : filterStatus === 'CRITICAL'
        ? req.status === 'PENDING'
        : filterStatus === 'ASSIGNED'
        ? req.status === 'ASSIGNED'
        : filterStatus === 'RESOLVED'
        ? req.status === 'RESOLVED' || req.status === 'COMPLETED'
        : true;

    const matchesSearch =
      (req.varkari_name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (req.varkari_username || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (req.request_code || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (req.problem_description || '').toLowerCase().includes(searchTerm.toLowerCase());

    return matchesStatus && matchesSearch;
  });

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 clean-card p-6 bg-white border-slate-200">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-2xl bg-rose-50 text-rose-600 border border-rose-200">
            <AlertTriangle className="w-7 h-7" />
          </div>
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
              Live Emergency SOS Monitoring
            </h2>
            <p className="text-xs text-slate-500 mt-0.5 font-medium">
              Real-time emergency distress signals triggered by Varkaris along the route
            </p>
          </div>
        </div>

        <button
          onClick={fetchRequests}
          className="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs flex items-center gap-2 transition-colors"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} /> Refresh Feed
        </button>
      </div>

      {/* Filters & Search Bar */}
      <div className="clean-card p-4 flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center space-x-2 w-full md:w-auto overflow-x-auto">
          <span className="text-xs font-semibold text-slate-500 flex items-center gap-1">
            <Filter className="w-3.5 h-3.5" /> Severity:
          </span>

          {['ALL', 'CRITICAL', 'ASSIGNED', 'RESOLVED'].map((st) => (
            <button
              key={st}
              onClick={() => setFilterStatus(st)}
              className={`px-3 py-1.5 rounded-xl font-bold text-xs transition-all ${
                filterStatus === st
                  ? 'bg-orange-600 text-white shadow-xs'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              {st === 'CRITICAL' ? '🔴 Unassigned Critical' : st === 'ASSIGNED' ? '🟡 Dispatched' : st === 'RESOLVED' ? '🟢 Resolved' : 'All Alerts'}
            </button>
          ))}
        </div>

        <div className="relative w-full md:w-72">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search SOS ID, Varkari Name..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-1.5 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 text-xs focus:outline-none focus:border-orange-500 focus:bg-white"
          />
        </div>
      </div>

      {/* SOS List Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filteredRequests.length === 0 ? (
          <div className="col-span-full clean-card p-12 text-center text-slate-500 space-y-3">
            <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto" />
            <h3 className="text-lg font-bold text-slate-900">No Emergency SOS Alerts Found</h3>
            <p className="text-xs max-w-sm mx-auto text-slate-500">
              All Varkari emergency assistance requests have been acknowledged and resolved.
            </p>
          </div>
        ) : (
          filteredRequests.map((sos) => (
            <SOSCard
              key={sos.id}
              sos={sos}
              onAssignVolunteer={handleOpenAssign}
              onResolve={handleResolveSos}
            />
          ))
        )}
      </div>

      <AssignVolunteerModal
        isOpen={assignModalOpen}
        onClose={() => setAssignModalOpen(false)}
        targetSos={targetSos}
        onAssigned={() => fetchRequests()}
      />
    </div>
  );
}
