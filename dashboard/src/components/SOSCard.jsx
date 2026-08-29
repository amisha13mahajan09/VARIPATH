import React from 'react';
import { AlertTriangle, Clock, MapPin, Phone, UserCheck, CheckCircle2, ShieldAlert } from 'lucide-react';

export default function SOSCard({ sos, onAssignVolunteer, onResolve }) {
  const isPending = sos.status === 'PENDING' || sos.status === 'UNASSIGNED';
  const isAssigned = sos.status === 'ASSIGNED';
  const isResolved = sos.status === 'RESOLVED' || sos.status === 'COMPLETED';

  return (
    <div className="clean-card p-4 space-y-3 relative">
      <div className="flex items-start justify-between">
        <div className="flex items-center space-x-2">
          <div className={`p-2 rounded-xl ${isPending ? 'bg-rose-100 text-rose-700' : isAssigned ? 'bg-amber-100 text-amber-700' : 'bg-emerald-100 text-emerald-700'}`}>
            <AlertTriangle className="w-5 h-5" />
          </div>
          <div>
            <span className="font-mono text-xs font-bold text-slate-500">#{sos.request_code}</span>
            <h4 className="font-bold text-slate-900 text-sm">{sos.varkari_name || sos.varkari_username}</h4>
          </div>
        </div>

        <span className={`px-2.5 py-0.5 rounded-full font-bold text-[10px] border ${
          isPending
            ? 'bg-rose-50 text-rose-700 border-rose-200'
            : isAssigned
            ? 'bg-amber-50 text-amber-700 border-amber-200'
            : 'bg-emerald-50 text-emerald-700 border-emerald-200'
        }`}>
          {isPending ? '🔴 CRITICAL SOS' : isAssigned ? '🟡 VOLUNTEER DISPATCHED' : '🟢 RESOLVED'}
        </span>
      </div>

      <p className="text-xs text-slate-700 font-medium bg-slate-50 p-2.5 rounded-xl border border-slate-100">
        "{sos.problem_description || 'Emergency assistance requested on route'}"
      </p>

      <div className="grid grid-cols-2 gap-2 text-xs text-slate-500">
        <div className="flex items-center gap-1">
          <Phone className="w-3.5 h-3.5 text-slate-400" />
          <span className="font-mono text-slate-700 font-medium">{sos.varkari_phone || '+91 98220 11223'}</span>
        </div>
        <div className="flex items-center gap-1">
          <Clock className="w-3.5 h-3.5 text-slate-400" />
          <span>{sos.created_at ? new Date(sos.created_at).toLocaleTimeString() : 'Recent'}</span>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex items-center justify-end space-x-2 pt-2 border-t border-slate-100">
        {!isResolved && (
          <>
            <button
              onClick={() => onAssignVolunteer(sos)}
              className="px-3 py-1.5 rounded-lg bg-orange-600 hover:bg-orange-700 text-white font-semibold text-xs flex items-center gap-1 shadow-xs transition-colors"
            >
              <UserCheck className="w-3.5 h-3.5" /> Dispatch Volunteer
            </button>
            <button
              onClick={() => onResolve(sos.id)}
              className="px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs flex items-center gap-1 transition-colors"
            >
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" /> Resolve
            </button>
          </>
        )}
      </div>
    </div>
  );
}
