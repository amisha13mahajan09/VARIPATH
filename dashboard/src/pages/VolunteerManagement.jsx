import React, { useState, useEffect } from 'react';
import { UserCheck, Phone, MapPin, Shield, CheckCircle2, Clock, RefreshCw } from 'lucide-react';
import { getVolunteers, assignVolunteer } from '../services/api';

export default function VolunteerManagement() {
  const [volunteers, setVolunteers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [assigningId, setAssigningId] = useState(null);
  const [taskText, setTaskText] = useState({});

  useEffect(() => {
    fetchVolunteersList();
  }, []);

  const fetchVolunteersList = async () => {
    setLoading(true);
    try {
      const res = await getVolunteers();
      if (res.success) {
        setVolunteers(res.volunteers || []);
      }
    } catch (err) {
      console.error('Fetch volunteers error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleAssignTask = async (volId) => {
    const desc = taskText[volId] || 'Wari Route Crowd & Medical Assistance';
    setAssigningId(volId);
    try {
      const res = await assignVolunteer(volId, null, desc);
      if (res.success) {
        fetchVolunteersList();
      }
    } catch (err) {
      alert('Failed to assign task');
    } finally {
      setAssigningId(null);
    }
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 clean-card p-6 bg-white border-slate-200">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-2xl bg-emerald-50 text-emerald-600 border border-emerald-200">
            <UserCheck className="w-7 h-7" />
          </div>
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
              Volunteer Command Hub
            </h2>
            <p className="text-xs text-slate-500 mt-0.5 font-medium">
              Manage active volunteers, emergency dispatch assignments, and live locations
            </p>
          </div>
        </div>

        <button
          onClick={fetchVolunteersList}
          className="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs flex items-center gap-2 transition-colors"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} /> Refresh Volunteers
        </button>
      </div>

      {/* Volunteer Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {loading ? (
          <div className="col-span-full py-12 text-center text-slate-400 font-medium">
            Loading active volunteers...
          </div>
        ) : volunteers.length === 0 ? (
          <div className="col-span-full py-12 text-center text-slate-400 font-medium">
            No volunteers registered in database.
          </div>
        ) : (
          volunteers.map((vol) => {
            const isDuty = vol.status === 'On Emergency Duty';
            const isAvail = vol.status === 'Available';

            return (
              <div key={vol.volunteer_id} className="clean-card p-5 space-y-3 relative">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <span className="font-mono text-xs font-bold text-orange-600 bg-orange-50 px-2 py-0.5 rounded border border-orange-200">
                      {vol.volunteer_id}
                    </span>
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${
                      isDuty
                        ? 'bg-rose-50 text-rose-700 border-rose-200'
                        : isAvail
                        ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                        : 'bg-slate-100 text-slate-700 border-slate-200'
                    }`}>
                      {vol.status}
                    </span>
                  </div>

                  <span className="text-[11px] text-slate-400 flex items-center gap-1">
                    <Clock className="w-3.5 h-3.5" />
                    {vol.last_seen ? new Date(vol.last_seen).toLocaleTimeString() : 'Active'}
                  </span>
                </div>

                <div>
                  <h4 className="font-extrabold text-slate-900 text-base">{vol.name}</h4>
                  <p className="text-xs text-orange-600 font-medium">📞 {vol.phone}</p>
                </div>

                {/* Current Task / Assignment */}
                <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100 text-xs">
                  <p className="text-slate-400 font-medium text-[11px]">Current Task Assignment:</p>
                  <p className="text-slate-900 font-semibold mt-0.5">
                    {vol.current_task || 'Route Guidance & Crowd Assistance'}
                  </p>
                </div>

                {/* Task Input & Assign */}
                <div className="space-y-2 pt-2 border-t border-slate-100">
                  <input
                    type="text"
                    placeholder="Enter new task description..."
                    value={taskText[vol.volunteer_id] || ''}
                    onChange={(e) => setTaskText({ ...taskText, [vol.volunteer_id]: e.target.value })}
                    className="w-full px-3 py-1.5 rounded-xl bg-slate-50 border border-slate-200 text-slate-900 text-xs focus:outline-none focus:border-orange-500 focus:bg-white"
                  />
                  <button
                    onClick={() => handleAssignTask(vol.volunteer_id)}
                    disabled={assigningId === vol.volunteer_id}
                    className="w-full py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs transition-colors flex items-center justify-center gap-1.5 disabled:opacity-50 shadow-xs"
                  >
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    {assigningId === vol.volunteer_id ? 'Assigning...' : 'Assign Duty'}
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
