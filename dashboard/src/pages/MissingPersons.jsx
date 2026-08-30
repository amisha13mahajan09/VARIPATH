import React, { useState, useEffect } from 'react';
import { UserX, Plus, MapPin, CheckCircle2, AlertCircle, RefreshCw } from 'lucide-react';
import MissingPersonCard from '../components/MissingPersonCard';
import ReportMissingModal from '../components/ReportMissingModal';
import {
  getActiveMissingPersons,
  getResolvedMissingPersons,
  verifyMissingPerson,
  markPersonFound
} from '../services/api';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import L from 'leaflet';

const missingIcon = L.divIcon({
  className: 'custom-leaflet-marker',
  html: `<div style="background-color: #E11D48; width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; border: 2px solid white; box-shadow: 0 4px 10px rgba(0,0,0,0.2);">🔍</div>`,
  iconSize: [32, 32],
  iconAnchor: [16, 16],
});

export default function MissingPersons() {
  const [activeTab, setActiveTab] = useState('ACTIVE'); // ACTIVE, FOUND, RESOLVED
  const [activeCases, setActiveCases] = useState([]);
  const [resolvedCases, setResolvedCases] = useState([]);
  const [loading, setLoading] = useState(true);
  const [reportModalOpen, setReportModalOpen] = useState(false);

  useEffect(() => {
    fetchMissingData();
  }, []);

  const fetchMissingData = async () => {
    setLoading(true);
    try {
      const [activeRes, resolvedRes] = await Promise.all([
        getActiveMissingPersons(),
        getResolvedMissingPersons(),
      ]);

      if (activeRes.success) {
        setActiveCases(activeRes.data || []);
      }
      if (resolvedRes.success) {
        setResolvedCases(resolvedRes.data || []);
      }
    } catch (err) {
      console.error('Fetch missing persons error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleVerify = async (id) => {
    try {
      await verifyMissingPerson(id, 'COMMAND_CENTER_ADMIN');
      fetchMissingData();
    } catch (err) {
      alert('Verification failed');
    }
  };

  const handleMarkFound = async (person) => {
    try {
      await markPersonFound(person.missing_person_id, {
        found_by: 'ORG-ADMIN',
        found_location: 'Volunteer Control Post',
        found_latitude: 18.3440,
        found_longitude: 74.0300,
      });
      fetchMissingData();
    } catch (err) {
      alert('Failed to update status');
    }
  };

  const pendingVerificationCases = activeCases.filter(
    (c) => c.status?.includes('Verification Pending') || c.verification_status === 'Pending'
  );

  const activeSearchCases = activeCases.filter(
    (c) => !c.status?.includes('Verification Pending') && c.verification_status !== 'Pending'
  );

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 clean-card p-6 bg-white border-slate-200">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-2xl bg-amber-50 text-amber-600 border border-amber-200">
            <UserX className="w-7 h-7" />
          </div>
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
              Missing Persons Management
            </h2>
            <p className="text-xs text-slate-500 mt-0.5 font-medium">
              Live tracking, sighting reports, volunteer verification, and reunion cases
            </p>
          </div>
        </div>

        <div className="flex items-center space-x-3">
          <button
            onClick={() => setReportModalOpen(true)}
            className="px-4 py-2 rounded-xl bg-orange-600 hover:bg-orange-700 text-white font-bold text-xs flex items-center gap-1.5 shadow-xs transition-colors"
          >
            <Plus className="w-4 h-4" /> Log Missing Report
          </button>
          <button
            onClick={fetchMissingData}
            className="p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 transition-colors"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="flex items-center space-x-2 border-b border-slate-200 pb-2">
        <button
          onClick={() => setActiveTab('ACTIVE')}
          className={`px-4 py-2 rounded-xl font-bold text-xs transition-all ${
            activeTab === 'ACTIVE'
              ? 'bg-orange-600 text-white shadow-xs'
              : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
          }`}
        >
          🔍 Active Missing ({activeSearchCases.length})
        </button>

        <button
          onClick={() => setActiveTab('FOUND')}
          className={`px-4 py-2 rounded-xl font-bold text-xs transition-all ${
            activeTab === 'FOUND'
              ? 'bg-amber-500 text-white shadow-xs'
              : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
          }`}
        >
          🟡 Found — Pending Verification ({pendingVerificationCases.length})
        </button>

        <button
          onClick={() => setActiveTab('RESOLVED')}
          className={`px-4 py-2 rounded-xl font-bold text-xs transition-all ${
            activeTab === 'RESOLVED'
              ? 'bg-emerald-600 text-white shadow-xs'
              : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
          }`}
        >
          🟢 Resolved History ({resolvedCases.length})
        </button>
      </div>

      {/* Main Grid: List + Map */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Cases List (2 cols) */}
        <div className="lg:col-span-2 space-y-4">
          {activeTab === 'ACTIVE' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {activeSearchCases.length === 0 ? (
                <div className="col-span-full clean-card p-8 text-center text-slate-500 text-xs font-medium">
                  No active missing person reports logged.
                </div>
              ) : (
                activeSearchCases.map((p) => (
                  <MissingPersonCard
                    key={p.id}
                    person={p}
                    onMarkFound={handleMarkFound}
                  />
                ))
              )}
            </div>
          )}

          {activeTab === 'FOUND' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {pendingVerificationCases.length === 0 ? (
                <div className="col-span-full clean-card p-8 text-center text-slate-500 text-xs font-medium">
                  No cases pending verification.
                </div>
              ) : (
                pendingVerificationCases.map((p) => (
                  <MissingPersonCard
                    key={p.id}
                    person={p}
                    onVerify={handleVerify}
                  />
                ))
              )}
            </div>
          )}

          {activeTab === 'RESOLVED' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {resolvedCases.length === 0 ? (
                <div className="col-span-full clean-card p-8 text-center text-slate-500 text-xs font-medium">
                  No resolved history records.
                </div>
              ) : (
                resolvedCases.map((p) => (
                  <MissingPersonCard key={p.id} person={p} />
                ))
              )}
            </div>
          )}
        </div>

        {/* Dedicated Missing Persons Map (1 col) */}
        <div className="clean-card p-4 flex flex-col h-[480px]">
          <h3 className="font-bold text-slate-900 text-sm mb-3 flex items-center gap-1.5">
            <MapPin className="w-4 h-4 text-orange-600" /> Missing Person Sightings Map
          </h3>
          <div className="flex-1 w-full rounded-xl overflow-hidden border border-slate-200">
            <MapContainer
              center={[18.3440, 74.0300]}
              zoom={9}
              style={{ width: '100%', height: '100%' }}
            >
              <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
              {activeCases.map((p) => (
                <Marker
                  key={p.id}
                  position={[p.reporter_latitude || 18.3440, p.reporter_longitude || 74.0300]}
                  icon={missingIcon}
                >
                  <Popup>
                    <div className="p-1 text-xs">
                      <p className="font-bold text-rose-600">{p.name} ({p.age} yrs)</p>
                      <p className="text-slate-600">Last Seen: {p.last_seen_location}</p>
                    </div>
                  </Popup>
                </Marker>
              ))}
            </MapContainer>
          </div>
        </div>
      </div>

      <ReportMissingModal
        isOpen={reportModalOpen}
        onClose={() => setReportModalOpen(false)}
        onCreated={() => fetchMissingData()}
      />
    </div>
  );
}
