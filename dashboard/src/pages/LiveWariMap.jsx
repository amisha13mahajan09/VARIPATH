import React, { useState, useEffect } from 'react';
import { MapPin, Layers, Radio, ShieldAlert, Stethoscope, Droplets, UserX, UserCheck, Flame, RefreshCw } from 'lucide-react';
import { MapContainer, TileLayer, Polyline, Marker, Popup } from 'react-leaflet';
import L from 'leaflet';
import { authenticVariRoute, wariMilestones } from '../services/variRouteData';
import {
  getAllAssistanceRequests,
  getActiveMissingPersons,
  getVolunteers,
  getVarkaris,
  getMedicalCamps,
  getFoodWaterPoints,
  getWeatherRiskZones
} from '../services/api';

const createIcon = (color, emoji) =>
  L.divIcon({
    className: 'custom-leaflet-marker',
    html: `<div style="background-color: ${color}; width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-size: 16px; border: 2px solid white; box-shadow: 0 4px 12px rgba(0,0,0,0.2);">${emoji}</div>`,
    iconSize: [34, 34],
    iconAnchor: [17, 17],
  });

const icons = {
  sos: createIcon('#E11D48', '🚨'),
  missing: createIcon('#D97706', '🔍'),
  volunteer: createIcon('#059669', '👮'),
  varkari: createIcon('#EA580C', '🚩'),
  camp: createIcon('#2563EB', '🏥'),
  water: createIcon('#0891B2', '💧'),
  heat: createIcon('#DC2626', '🔥'),
  milestone: createIcon('#7C3AED', '📍'),
};

export default function LiveWariMap() {
  const [layers, setLayers] = useState({
    route: true,
    sos: true,
    missing: true,
    volunteers: true,
    varkaris: true,
    camps: true,
    water: true,
    heat: true,
  });

  const [sosList, setSosList] = useState([]);
  const [missingList, setMissingList] = useState([]);
  const [volunteersList, setVolunteersList] = useState([]);
  const [varkarisList, setVarkarisList] = useState([]);
  const [campsList, setCampsList] = useState([]);
  const [waterList, setWaterList] = useState([]);
  const [heatList, setHeatList] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchMapData();
    const interval = setInterval(fetchMapData, 8000);
    return () => clearInterval(interval);
  }, []);

  const fetchMapData = async () => {
    try {
      const [sosRes, missRes, volRes, vkRes, campRes, waterRes, heatRes] = await Promise.allSettled([
        getAllAssistanceRequests(),
        getActiveMissingPersons(),
        getVolunteers(),
        getVarkaris(),
        getMedicalCamps(),
        getFoodWaterPoints(),
        getWeatherRiskZones(),
      ]);

      if (sosRes.status === 'fulfilled' && sosRes.value.success) setSosList(sosRes.value.data || []);
      if (missRes.status === 'fulfilled' && missRes.value.success) setMissingList(missRes.value.data || []);
      if (volRes.status === 'fulfilled' && volRes.value.success) setVolunteersList(volRes.value.volunteers || []);
      if (vkRes.status === 'fulfilled' && vkRes.value.success) setVarkarisList(vkRes.value.varkaris || []);
      if (campRes.status === 'fulfilled' && campRes.value.success) setCampsList(campRes.value.data || []);
      if (waterRes.status === 'fulfilled' && waterRes.value.success) setWaterList(waterRes.value.data || []);
      if (heatRes.status === 'fulfilled' && heatRes.value.success) setHeatList(heatRes.value.zones || []);
    } catch (err) {
      console.error('Error loading map layers:', err);
    } finally {
      setLoading(false);
    }
  };

  const toggleLayer = (key) => {
    setLayers({ ...layers, [key]: !layers[key] });
  };

  return (
    <div className="space-y-4 pb-12">
      {/* Top Controls Banner */}
      <div className="clean-card p-4 flex flex-col md:flex-row items-center justify-between gap-4 bg-white border-slate-200">
        <div className="flex items-center space-x-3">
          <div className="p-2.5 rounded-xl bg-orange-50 text-orange-600 border border-orange-200">
            <MapPin className="w-6 h-6" />
          </div>
          <div>
            <h2 className="text-lg font-extrabold text-slate-900 flex items-center gap-2">
              Live Wari Command Map (NH 965 Route)
              <span className="text-[10px] bg-emerald-50 text-emerald-700 border border-emerald-200 px-2 py-0.5 rounded-full flex items-center gap-1 font-bold">
                <Radio className="w-2.5 h-2.5 text-emerald-600 animate-pulse" /> Live Telemetry
              </span>
            </h2>
            <p className="text-xs text-slate-500 font-medium">
              Interactive multi-layer geospatial monitoring from Pune Karve Nagar to Pandharpur Temple
            </p>
          </div>
        </div>

        <button
          onClick={fetchMapData}
          className="px-3.5 py-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs flex items-center gap-2 transition-colors"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} /> Refresh Map Layers
        </button>
      </div>

      {/* Layer Filters Controls */}
      <div className="clean-card p-3 flex items-center space-x-2 overflow-x-auto text-xs">
        <span className="text-slate-500 font-semibold flex items-center gap-1">
          <Layers className="w-4 h-4 text-orange-600" /> Map Layers:
        </span>

        {[
          { key: 'route', label: 'Wari Route', color: 'bg-orange-600' },
          { key: 'sos', label: 'SOS Alerts 🚨', color: 'bg-rose-600' },
          { key: 'missing', label: 'Missing Persons 🔍', color: 'bg-amber-600' },
          { key: 'volunteers', label: 'Volunteers 👮', color: 'bg-emerald-600' },
          { key: 'varkaris', label: 'Varkaris 🚩', color: 'bg-orange-700' },
          { key: 'camps', label: 'Medical Camps 🏥', color: 'bg-blue-600' },
          { key: 'water', label: 'Water Points 💧', color: 'bg-cyan-600' },
          { key: 'heat', label: 'Heat Risk Zones 🔥', color: 'bg-rose-700' },
        ].map((item) => (
          <button
            key={item.key}
            onClick={() => toggleLayer(item.key)}
            className={`px-3 py-1.5 rounded-xl font-bold transition-all flex items-center gap-1.5 ${
              layers[item.key]
                ? `${item.color} text-white shadow-xs`
                : 'bg-slate-100 text-slate-500 border border-slate-200'
            }`}
          >
            <span className={`w-2 h-2 rounded-full ${layers[item.key] ? 'bg-white' : 'bg-slate-400'}`} />
            {item.label}
          </button>
        ))}
      </div>

      {/* Full-Screen Map Container */}
      <div className="clean-card p-2 h-[650px] relative overflow-hidden border-slate-200">
        <MapContainer
          center={[18.3440, 74.0300]}
          zoom={9}
          style={{ width: '100%', height: '100%' }}
        >
          <TileLayer
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            attribution='&copy; OpenStreetMap | VariPath Command Center'
          />

          {/* Polyline Route */}
          {layers.route && (
            <Polyline positions={authenticVariRoute} color="#EA580C" weight={5} opacity={0.85} />
          )}

          {/* Milestones */}
          {layers.route &&
            wariMilestones.map((m, idx) => (
              <Marker key={idx} position={m.location} icon={icons.milestone}>
                <Popup>
                  <div className="p-1">
                    <h4 className="font-bold text-sm text-purple-700">{m.name}</h4>
                    <p className="text-xs text-slate-600">{m.desc}</p>
                  </div>
                </Popup>
              </Marker>
            ))}

          {/* SOS Markers */}
          {layers.sos &&
            sosList.map((sos) => (
              <Marker key={sos.id} position={[sos.latitude || 18.4902, sos.longitude || 73.8130]} icon={icons.sos}>
                <Popup>
                  <div className="p-1 text-xs">
                    <p className="font-bold text-rose-600">EMERGENCY SOS #{sos.request_code}</p>
                    <p className="font-semibold text-slate-900 mt-0.5">{sos.varkari_name || sos.varkari_username}</p>
                    <p className="text-slate-600">"{sos.problem_description}"</p>
                    <p className="text-[10px] text-amber-600 mt-1 font-bold">Status: {sos.status}</p>
                  </div>
                </Popup>
              </Marker>
            ))}

          {/* Missing Person Markers */}
          {layers.missing &&
            missingList.map((p) => (
              <Marker key={p.id} position={[p.reporter_latitude || 18.3440, p.reporter_longitude || 74.0300]} icon={icons.missing}>
                <Popup>
                  <div className="p-1 text-xs">
                    <p className="font-bold text-amber-600">MISSING PERSON #{p.missing_person_id}</p>
                    <p className="font-semibold text-slate-900 mt-0.5">{p.name} ({p.age} yrs)</p>
                    <p className="text-slate-600">Last Seen: {p.last_seen_location}</p>
                  </div>
                </Popup>
              </Marker>
            ))}

          {/* Volunteers Markers */}
          {layers.volunteers &&
            volunteersList.map((vol) => (
              <Marker key={vol.id} position={[vol.latitude || 18.4910, vol.longitude || 73.8140]} icon={icons.volunteer}>
                <Popup>
                  <div className="p-1 text-xs">
                    <p className="font-bold text-emerald-600">VOLUNTEER #{vol.volunteer_id}</p>
                    <p className="font-semibold text-slate-900">{vol.name}</p>
                    <p className="text-slate-600 font-mono">📞 {vol.phone}</p>
                    <p className="text-[10px] text-amber-600 mt-1 font-bold">Duty: {vol.status}</p>
                  </div>
                </Popup>
              </Marker>
            ))}

          {/* Varkaris Markers */}
          {layers.varkaris &&
            varkarisList.map((vk) => (
              <Marker key={vk.varkari_id} position={[vk.latitude || 18.4902, vk.longitude || 73.8130]} icon={icons.varkari}>
                <Popup>
                  <div className="p-1 text-xs">
                    <p className="font-bold text-orange-600">VARKARI #{vk.varkari_id}</p>
                    <p className="font-semibold text-slate-900">{vk.name}</p>
                    <p className="text-slate-600">Status: {vk.status}</p>
                  </div>
                </Popup>
              </Marker>
            ))}

          {/* Medical Camps */}
          {layers.camps &&
            campsList.map((c) => (
              <Marker key={c.camp_id} position={[c.latitude, c.longitude]} icon={icons.camp}>
                <Popup>
                  <div className="p-1 text-xs">
                    <p className="font-bold text-blue-600">{c.name}</p>
                    <p className="text-slate-600">Doctor: {c.doctor_in_charge}</p>
                    <p className="text-emerald-600 font-mono">📞 {c.contact_phone}</p>
                  </div>
                </Popup>
              </Marker>
            ))}

          {/* Water Points */}
          {layers.water &&
            waterList.map((w) => (
              <Marker key={w.point_id} position={[w.latitude, w.longitude]} icon={icons.water}>
                <Popup>
                  <div className="p-1 text-xs">
                    <p className="font-bold text-cyan-600">{w.name}</p>
                    <p className="text-slate-600">Status: {w.status}</p>
                  </div>
                </Popup>
              </Marker>
            ))}

          {/* Heat Risk Zones */}
          {layers.heat &&
            heatList.map((h) => (
              <Marker key={h.id} position={[h.latitude, h.longitude]} icon={icons.heat}>
                <Popup>
                  <div className="p-1 text-xs">
                    <p className="font-bold text-rose-600">HEAT RISK ZONE — {h.temperature}°C</p>
                    <p className="text-slate-600">{h.advisory_english}</p>
                  </div>
                </Popup>
              </Marker>
            ))}
        </MapContainer>
      </div>
    </div>
  );
}
