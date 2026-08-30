import React, { useState, useEffect } from 'react';
import {
  Users,
  UserCheck,
  AlertTriangle,
  UserX,
  Stethoscope,
  Pill,
  Droplets,
  Flame,
  Radio,
  RefreshCw,
  MapPin,
  Clock,
  ArrowRight,
  ShieldCheck,
  CheckCircle2
} from 'lucide-react';
import StatCard from '../components/StatCard';
import SOSCard from '../components/SOSCard';
import MissingPersonCard from '../components/MissingPersonCard';
import AssignVolunteerModal from '../components/AssignVolunteerModal';
import VarkariDetailModal from '../components/VarkariDetailModal';
import {
  getDashboardStats,
  getAllAssistanceRequests,
  getActiveMissingPersons,
  getNotifications,
  updateSosStatus,
  verifyMissingPerson,
  markPersonFound
} from '../services/api';
import { authenticVariRoute, wariMilestones } from '../services/variRouteData';
import { MapContainer, TileLayer, Polyline, Marker, Popup } from 'react-leaflet';
import L from 'leaflet';

const createIcon = (color, emoji) =>
  L.divIcon({
    className: 'custom-leaflet-marker',
    html: `<div style="background-color: ${color}; width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; border: 2px solid white; box-shadow: 0 4px 10px rgba(0,0,0,0.2);">${emoji}</div>`,
    iconSize: [32, 32],
    iconAnchor: [16, 16],
  });

const icons = {
  start: createIcon('#EA580C', '🚩'),
  sos: createIcon('#E11D48', '🚨'),
  missing: createIcon('#D97706', '🔍'),
  camp: createIcon('#059669', '🏥'),
  water: createIcon('#0284C7', '💧'),
  heat: createIcon('#DC2626', '🔥'),
  milestone: createIcon('#7C3AED', '📍'),
};

export default function DashboardHome() {
  const [stats, setStats] = useState({
    total_varkaris: 12450,
    active_volunteers: 45,
    active_sos: 2,
    active_missing: 1,
    medical_camps: 4,
    low_medicine_stock: 2,
    active_water_points: 5,
    heat_risk_zones: 3,
  });

  const [sosList, setSosList] = useState([]);
  const [missingList, setMissingList] = useState([]);
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState(new Date().toLocaleTimeString());

  // Modal States
  const [assignModalOpen, setAssignModalOpen] = useState(false);
  const [targetSos, setTargetSos] = useState(null);
  const [selectedVarkari, setSelectedVarkari] = useState(null);
  const [varkariModalOpen, setVarkariModalOpen] = useState(false);

  useEffect(() => {
    loadDashboardData();
    const interval = setInterval(loadDashboardData, 6000);
    return () => clearInterval(interval);
  }, []);

  const loadDashboardData = async () => {
    try {
      const [statsRes, sosRes, missingRes, notifRes] = await Promise.allSettled([
        getDashboardStats(),
        getAllAssistanceRequests(),
        getActiveMissingPersons(),
        getNotifications(),
      ]);

      if (statsRes.status === 'fulfilled' && statsRes.value.success) {
        setStats(statsRes.value.stats);
      }
      if (sosRes.status === 'fulfilled' && sosRes.value.success) {
        setSosList(sosRes.value.data || []);
      }
      if (missingRes.status === 'fulfilled' && missingRes.value.success) {
        setMissingList(missingRes.value.data || []);
      }
      if (notifRes.status === 'fulfilled' && notifRes.value.success) {
        setNotifications(notifRes.value.notifications || []);
      }

      setLastUpdated(new Date().toLocaleTimeString());
    } catch (err) {
      console.error('Error loading dashboard:', err);
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
      loadDashboardData();
    } catch (err) {
      alert('Failed to resolve SOS');
    }
  };

  const handleVerifyMissing = async (missingId) => {
    try {
      await verifyMissingPerson(missingId, 'COMMAND_CENTER_ADMIN');
      loadDashboardData();
    } catch (err) {
      alert('Verification failed');
    }
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Clean Header Banner */}
      <div className="clean-card p-6 flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white border-slate-200">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight font-marathi">
              वारीपथ (VariPath) Command Center
            </h2>
            <span className="px-2.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 font-bold text-xs border border-emerald-200">
              NH 965 Active Route
            </span>
          </div>
          <p className="text-xs text-slate-500 mt-1 font-medium">
            Real-Time Emergency Response & Crowd Safety Monitoring • Pune to Pandharpur Route
          </p>
        </div>

        <div className="flex items-center gap-3">
          <span className="text-xs text-slate-500 font-mono">
            Refreshed: <strong className="text-slate-900">{lastUpdated}</strong>
          </span>
          <button
            onClick={loadDashboardData}
            className="p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 transition-colors"
            title="Refresh Data Now"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Real-time Summary Cards Grid (8 Clean Cards) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="Total Varkaris"
          count={stats.total_varkaris || 12450}
          subtitle="Registered & Active on Route"
          icon={Users}
          color="orange"
          linkTo="/varkaris"
          badgeText="Active Track"
        />

        <StatCard
          title="Active Volunteers"
          count={stats.active_volunteers || 45}
          subtitle={`Out of ${stats.total_volunteers || 50} total volunteers`}
          icon={UserCheck}
          color="emerald"
          linkTo="/volunteers"
          badgeText="On Duty"
        />

        <StatCard
          title="Active SOS Emergencies"
          count={stats.active_sos || 0}
          subtitle={`${stats.resolved_sos || 0} Cases Resolved Today`}
          icon={AlertTriangle}
          color="red"
          pulse={stats.active_sos > 0}
          linkTo="/sos"
          badgeText={stats.active_sos > 0 ? 'CRITICAL ALERT' : 'Normal'}
        />

        <StatCard
          title="Active Missing Persons"
          count={stats.active_missing || 0}
          subtitle={`${stats.found_missing || 0} Cases Resolved`}
          icon={UserX}
          color="amber"
          linkTo="/missing-persons"
          badgeText="Search Active"
        />

        <StatCard
          title="Medical Camps"
          count={stats.medical_camps || 4}
          subtitle="Emergency First-Aid Units"
          icon={Stethoscope}
          color="blue"
          linkTo="/medical-camps"
          badgeText="24/7 Active"
        />

        <StatCard
          title="Low Stock Medicines"
          count={stats.low_medicine_stock || 2}
          subtitle="Items Needing Replenishment"
          icon={Pill}
          color="purple"
          linkTo="/medicines"
          badgeText="Restock Alert"
        />

        <StatCard
          title="Active Water Points"
          count={stats.active_water_points || 5}
          subtitle="Hydration & Food Hubs"
          icon={Droplets}
          color="blue"
          linkTo="/food-water"
          badgeText="Hydration"
        />

        <StatCard
          title="Heat-Risk Zones"
          count={stats.heat_risk_zones || 3}
          subtitle="Dive Ghat Heat Alert (39°C)"
          icon={Flame}
          color="red"
          linkTo="/weather-risk"
          badgeText="Heat Warning"
        />
      </div>

      {/* Main Section: Embedded Live Map + Side Alert Feeds */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Live Wari Map (2 Columns) */}
        <div className="lg:col-span-2 clean-card p-4 flex flex-col h-[500px] relative">
          <div className="flex items-center justify-between mb-3 px-1">
            <div className="flex items-center space-x-2">
              <MapPin className="w-5 h-5 text-orange-600" />
              <h3 className="font-bold text-slate-900 text-base">Live Wari Route Command Map</h3>
            </div>
            <a
              href="/live-map"
              className="text-xs font-bold text-orange-600 hover:text-orange-700 flex items-center gap-1"
            >
              Full Interactive Map &rarr;
            </a>
          </div>

          {/* Leaflet Map */}
          <div className="flex-1 w-full rounded-xl overflow-hidden border border-slate-200">
            <MapContainer
              center={[18.3440, 74.0300]}
              zoom={9}
              style={{ width: '100%', height: '100%' }}
              scrollWheelZoom={false}
            >
              <TileLayer
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                attribution='&copy; OpenStreetMap contributors | VariPath'
              />

              {/* Polyline Authentic Route */}
              <Polyline
                positions={authenticVariRoute}
                color="#EA580C"
                weight={5}
                opacity={0.85}
              />

              {/* Milestones Markers */}
              {wariMilestones.map((m, idx) => (
                <Marker key={idx} position={m.location} icon={icons.milestone}>
                  <Popup>
                    <div className="p-1">
                      <h4 className="font-bold text-sm text-purple-700">{m.name}</h4>
                      <p className="text-xs text-slate-600">{m.desc}</p>
                    </div>
                  </Popup>
                </Marker>
              ))}

              {/* Active SOS Markers */}
              {sosList.map((sos) => (
                <Marker key={sos.id} position={[sos.latitude || 18.4902, sos.longitude || 73.8130]} icon={icons.sos}>
                  <Popup>
                    <div className="p-1 text-xs">
                      <span className="font-bold text-rose-600">EMERGENCY SOS #{sos.request_code}</span>
                      <p className="font-semibold text-slate-900 mt-1">{sos.varkari_name || sos.varkari_username}</p>
                      <p className="text-slate-600">{sos.problem_description}</p>
                      <button
                        onClick={() => handleOpenAssign(sos)}
                        className="mt-2 px-2 py-1 bg-orange-600 text-white font-bold rounded text-[10px]"
                      >
                        Dispatch Volunteer
                      </button>
                    </div>
                  </Popup>
                </Marker>
              ))}
            </MapContainer>
          </div>
        </div>

        {/* Live Active Emergency & Missing Feed (1 Column) */}
        <div className="space-y-6">
          {/* Active SOS Feed */}
          <div className="clean-card p-4 space-y-3">
            <div className="flex items-center justify-between border-b border-slate-100 pb-2">
              <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 text-rose-600" /> Active SOS Requests
              </h3>
              <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-rose-50 text-rose-700 border border-rose-200">
                {sosList.filter(s => s.status !== 'RESOLVED').length} Live
              </span>
            </div>

            <div className="space-y-3 max-h-[220px] overflow-y-auto pr-1">
              {sosList.length === 0 ? (
                <div className="p-4 text-center text-xs text-slate-500">
                  <CheckCircle2 className="w-6 h-6 text-emerald-500 mx-auto mb-1" />
                  No active emergency SOS alerts.
                </div>
              ) : (
                sosList.slice(0, 3).map((sos) => (
                  <SOSCard
                    key={sos.id}
                    sos={sos}
                    onAssignVolunteer={handleOpenAssign}
                    onResolve={handleResolveSos}
                  />
                ))
              )}
            </div>
          </div>

          {/* Active Missing Persons Feed */}
          <div className="clean-card p-4 space-y-3">
            <div className="flex items-center justify-between border-b border-slate-100 pb-2">
              <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                <UserX className="w-4 h-4 text-amber-600" /> Active Missing Persons
              </h3>
              <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-50 text-amber-700 border border-amber-200">
                {missingList.length} Active
              </span>
            </div>

            <div className="space-y-3 max-h-[220px] overflow-y-auto pr-1">
              {missingList.length === 0 ? (
                <div className="p-4 text-center text-xs text-slate-500">
                  No missing person reports logged.
                </div>
              ) : (
                missingList.slice(0, 2).map((person) => (
                  <MissingPersonCard
                    key={person.id}
                    person={person}
                    onVerify={handleVerifyMissing}
                  />
                ))
              )}
            </div>
          </div>
        </div>
      </div>

      {/* System Notifications Log */}
      <div className="clean-card p-5">
        <div className="flex items-center justify-between mb-3 pb-2 border-b border-slate-100">
          <h3 className="font-bold text-slate-900 text-base">System Notifications & Alerts Log</h3>
          <a href="/notifications" className="text-xs text-orange-600 hover:text-orange-700 font-semibold">
            View All Logs &rarr;
          </a>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          {notifications.slice(0, 6).map((n) => (
            <div key={n.id} className="p-3 rounded-xl bg-slate-50 border border-slate-200 text-xs">
              <div className="flex items-center justify-between mb-1">
                <span className="font-bold text-orange-700">{n.title}</span>
                <span className="text-[10px] text-slate-400">{n.created_at ? new Date(n.created_at).toLocaleTimeString() : 'Recent'}</span>
              </div>
              <p className="text-slate-600">{n.message}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Modals */}
      <AssignVolunteerModal
        isOpen={assignModalOpen}
        onClose={() => setAssignModalOpen(false)}
        targetSos={targetSos}
        onAssigned={() => loadDashboardData()}
      />

      <VarkariDetailModal
        varkari={selectedVarkari}
        isOpen={varkariModalOpen}
        onClose={() => setVarkariModalOpen(false)}
      />
    </div>
  );
}
