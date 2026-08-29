import React, { useState, useEffect } from 'react';
import { X, UserCheck, Phone, MapPin, CheckCircle2, ShieldAlert } from 'lucide-react';
import { getVolunteers, assignSosVolunteer } from '../services/api';

export default function AssignVolunteerModal({ isOpen, onClose, targetSos, onAssigned }) {
  const [volunteers, setVolunteers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [selectedVol, setSelectedVol] = useState(null);
  const [assigning, setAssigning] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (isOpen) {
      fetchVolunteersList();
    }
  }, [isOpen]);

  const fetchVolunteersList = async () => {
    setLoading(true);
    try {
      const res = await getVolunteers();
      if (res.success && res.volunteers) {
        setVolunteers(res.volunteers);
        // Default pick first available
        const avail = res.volunteers.find(v => v.status === 'Available' || v.is_active);
        if (avail) setSelectedVol(avail.volunteer_id);
      }
    } catch (err) {
      setError('Unable to load volunteer list.');
    } finally {
      setLoading(false);
    }
  };

  const handleDispatch = async () => {
    if (!selectedVol || !targetSos) return;
    setAssigning(true);
    setError('');
    try {
      const res = await assignSosVolunteer(targetSos.id, selectedVol);
      if (res.success) {
        if (onAssigned) onAssigned(res.data);
        onClose();
      } else {
        setError(res.message || 'Assignment failed');
      }
    } catch (err) {
      setError(err.message || 'Assignment failed');
    } finally {
      setAssigning(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm animate-fade-in">
      <div className="glass-panel w-full max-w-lg p-6 relative border-slate-700 shadow-2xl">
        <button
          onClick={onClose}
          className="absolute right-4 top-4 p-1.5 rounded-lg bg-slate-800 text-slate-400 hover:text-white"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="flex items-center space-x-3 mb-4">
          <div className="p-3 rounded-xl bg-orange-500/20 text-orange-400 border border-orange-500/30">
            <UserCheck className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-white">Dispatch Volunteer</h3>
            <p className="text-xs text-slate-400">Emergency SOS #{targetSos?.request_code || targetSos?.id}</p>
          </div>
        </div>

        {/* SOS Summary Box */}
        <div className="p-3 rounded-xl bg-slate-950 border border-slate-800 text-xs mb-4 space-y-1">
          <p className="font-semibold text-white">Varkari: {targetSos?.varkari_name || targetSos?.varkari_username}</p>
          <p className="text-red-400 font-medium">"{targetSos?.problem_description || targetSos?.health_condition}"</p>
        </div>

        {error && (
          <div className="p-3 rounded-xl bg-red-950/40 border border-red-800 text-red-300 text-xs mb-3">
            {error}
          </div>
        )}

        {/* Volunteer List */}
        <div className="space-y-2 max-h-60 overflow-y-auto my-3 pr-1">
          <p className="text-xs font-semibold text-slate-400 uppercase">Select Available Volunteer:</p>
          {loading ? (
            <p className="text-xs text-slate-400 py-4 text-center">Loading volunteers roster...</p>
          ) : volunteers.length === 0 ? (
            <p className="text-xs text-slate-400 py-4 text-center">No active volunteers found.</p>
          ) : (
            volunteers.map((vol) => (
              <label
                key={vol.volunteer_id}
                onClick={() => setSelectedVol(vol.volunteer_id)}
                className={`flex items-center justify-between p-3 rounded-xl border cursor-pointer transition-all ${
                  selectedVol === vol.volunteer_id
                    ? 'bg-orange-500/15 border-orange-500/50 text-white'
                    : 'bg-slate-950/40 border-slate-800 text-slate-300 hover:bg-slate-800/40'
                }`}
              >
                <div className="flex items-center space-x-3">
                  <input
                    type="radio"
                    name="volunteer"
                    checked={selectedVol === vol.volunteer_id}
                    onChange={() => setSelectedVol(vol.volunteer_id)}
                    className="text-orange-500 focus:ring-orange-500"
                  />
                  <div>
                    <p className="font-semibold text-sm">{vol.name} <span className="text-xs font-mono text-slate-400">({vol.volunteer_id})</span></p>
                    <p className="text-xs text-slate-400 flex items-center gap-2 mt-0.5">
                      <span>📞 {vol.phone}</span>
                      <span className={`font-bold px-1.5 py-0.2 rounded ${vol.status === 'Available' ? 'text-emerald-400 bg-emerald-500/10' : 'text-amber-400 bg-amber-500/10'}`}>
                        {vol.status}
                      </span>
                    </p>
                  </div>
                </div>
              </label>
            ))
          )}
        </div>

        {/* Modal Buttons */}
        <div className="flex items-center justify-end space-x-3 pt-3 border-t border-slate-800">
          <button
            onClick={onClose}
            className="px-4 py-2 rounded-xl bg-slate-800 text-slate-300 hover:bg-slate-700 text-xs font-semibold"
          >
            Cancel
          </button>
          <button
            onClick={handleDispatch}
            disabled={assigning || !selectedVol}
            className="px-5 py-2 rounded-xl bg-gradient-to-r from-orange-500 to-amber-600 hover:from-orange-600 hover:to-amber-700 text-white font-bold text-xs shadow-lg shadow-orange-500/20 disabled:opacity-50"
          >
            {assigning ? 'Assigning...' : 'Confirm Volunteer Dispatch'}
          </button>
        </div>
      </div>
    </div>
  );
}
