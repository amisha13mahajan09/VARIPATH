import React, { useState } from 'react';
import { X, UserX, AlertTriangle, Upload, CheckCircle2 } from 'lucide-react';
import { reportMissingPerson } from '../services/api';

export default function ReportMissingModal({ isOpen, onClose, onCreated }) {
  const [formData, setFormData] = useState({
    name: '',
    age: '',
    gender: 'Male',
    contact_number: '',
    last_seen_location: 'Saswad Palkhi Maidan',
    physical_description: '',
    clothes_description: '',
    reporter_id: 'ORG-ADMIN',
    reporter_type: 'ORGANIZER',
    reporter_location: 'Command Center',
  });

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  if (!isOpen) return null;

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name || !formData.age || !formData.last_seen_location) {
      setError('Please fill in required fields (Name, Age, Last Seen Location).');
      return;
    }

    setSubmitting(true);
    setError('');

    try {
      const res = await reportMissingPerson(formData);
      if (res.success) {
        if (onCreated) onCreated();
        onClose();
      } else {
        setError(res.message || 'Failed to submit report.');
      }
    } catch (err) {
      setError(err.message || 'Failed to submit report.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm animate-fade-in">
      <div className="glass-panel w-full max-w-xl p-6 relative border-slate-700 shadow-2xl">
        <button
          onClick={onClose}
          className="absolute right-4 top-4 p-1.5 rounded-lg bg-slate-800 text-slate-400 hover:text-white"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="flex items-center space-x-3 mb-4 pb-3 border-b border-slate-800">
          <div className="p-3 rounded-xl bg-red-500/20 text-red-400 border border-red-500/30">
            <UserX className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-white">Log New Missing Person Report</h3>
            <p className="text-xs text-slate-400">Adds an active missing case to the live command center map & database</p>
          </div>
        </div>

        {error && (
          <div className="p-3 rounded-xl bg-red-950/40 border border-red-800 text-red-300 text-xs mb-4">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4 text-xs">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block text-slate-400 font-medium mb-1">Full Name *</label>
              <input
                type="text"
                name="name"
                required
                placeholder="e.g. Shantabai Jadhav"
                value={formData.name}
                onChange={handleChange}
                className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:border-orange-500"
              />
            </div>

            <div>
              <label className="block text-slate-400 font-medium mb-1">Age *</label>
              <input
                type="number"
                name="age"
                required
                placeholder="e.g. 68"
                value={formData.age}
                onChange={handleChange}
                className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:border-orange-500"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block text-slate-400 font-medium mb-1">Gender *</label>
              <select
                name="gender"
                value={formData.gender}
                onChange={handleChange}
                className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:border-orange-500"
              >
                <option value="Male">Male</option>
                <option value="Female">Female</option>
                <option value="Other">Other</option>
              </select>
            </div>

            <div>
              <label className="block text-slate-400 font-medium mb-1">Contact Phone</label>
              <input
                type="text"
                name="contact_number"
                placeholder="e.g. 9822011223"
                value={formData.contact_number}
                onChange={handleChange}
                className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:border-orange-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-slate-400 font-medium mb-1">Last Seen Location *</label>
            <input
              type="text"
              name="last_seen_location"
              required
              placeholder="e.g. Dive Ghat Top / Saswad Palkhi Maidan"
              value={formData.last_seen_location}
              onChange={handleChange}
              className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:border-orange-500"
            />
          </div>

          <div>
            <label className="block text-slate-400 font-medium mb-1">Physical & Clothing Description</label>
            <textarea
              name="physical_description"
              rows={3}
              placeholder="e.g. Height 5ft 2in, wearing green nauvari saree with brass pot..."
              value={formData.physical_description}
              onChange={handleChange}
              className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:border-orange-500"
            />
          </div>

          <div className="flex items-center justify-end space-x-3 pt-3 border-t border-slate-800">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 rounded-xl bg-slate-800 text-slate-300 hover:bg-slate-700 text-xs font-semibold"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="px-5 py-2 rounded-xl bg-gradient-to-r from-red-600 to-orange-600 hover:from-red-700 hover:to-orange-700 text-white font-bold text-xs shadow-lg shadow-red-600/20 disabled:opacity-50"
            >
              {submitting ? 'Submitting...' : 'Submit Missing Report'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
