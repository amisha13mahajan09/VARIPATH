import React from 'react';
import { UserX, MapPin, Phone, CheckCircle2, ShieldAlert } from 'lucide-react';

export default function MissingPersonCard({ person, onVerify, onMarkFound }) {
  const isFoundPending = person.status?.includes('Verification Pending') || person.verification_status === 'Pending';
  const isResolved = person.status === 'FOUND_AND_REUNITED' || person.status === 'Resolved';

  return (
    <div className="clean-card p-4 space-y-3 relative">
      <div className="flex items-start justify-between">
        <div className="flex items-center space-x-2">
          <div className={`p-2 rounded-xl ${isResolved ? 'bg-emerald-100 text-emerald-700' : isFoundPending ? 'bg-amber-100 text-amber-700' : 'bg-rose-100 text-rose-700'}`}>
            <UserX className="w-5 h-5" />
          </div>
          <div>
            <span className="font-mono text-xs font-bold text-slate-500">#{person.missing_person_id}</span>
            <h4 className="font-bold text-slate-900 text-sm">{person.name} ({person.age} yrs)</h4>
          </div>
        </div>

        <span className={`px-2.5 py-0.5 rounded-full font-bold text-[10px] border ${
          isResolved
            ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
            : isFoundPending
            ? 'bg-amber-50 text-amber-700 border-amber-200'
            : 'bg-rose-50 text-rose-700 border-rose-200'
        }`}>
          {person.status || 'ACTIVE SEARCH'}
        </span>
      </div>

      <div className="space-y-1 text-xs text-slate-600">
        <p className="flex items-center gap-1">
          <MapPin className="w-3.5 h-3.5 text-orange-600 flex-shrink-0" />
          <span>Last Seen: <strong className="text-slate-900">{person.last_seen_location || 'Near Karve Nagar'}</strong></span>
        </p>
        <p className="flex items-center gap-1">
          <Phone className="w-3.5 h-3.5 text-slate-400 flex-shrink-0" />
          <span>Reporter Contact: <strong className="text-slate-900 font-mono">{person.reporter_phone}</strong></span>
        </p>
      </div>

      {person.description && (
        <p className="text-xs text-slate-600 bg-slate-50 p-2 rounded-lg border border-slate-100">
          Clothing / Identifiers: {person.description}
        </p>
      )}

      {/* Action Buttons */}
      <div className="flex items-center justify-end space-x-2 pt-2 border-t border-slate-100">
        {isFoundPending && onVerify && (
          <button
            onClick={() => onVerify(person.id)}
            className="px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-xs flex items-center gap-1 shadow-xs transition-colors"
          >
            <CheckCircle2 className="w-3.5 h-3.5" /> Verify & Reunite
          </button>
        )}

        {!isFoundPending && !isResolved && onMarkFound && (
          <button
            onClick={() => onMarkFound(person)}
            className="px-3 py-1.5 rounded-lg bg-amber-500 hover:bg-amber-600 text-white font-semibold text-xs flex items-center gap-1 shadow-xs transition-colors"
          >
            Report Found Sighting
          </button>
        )}
      </div>
    </div>
  );
}
