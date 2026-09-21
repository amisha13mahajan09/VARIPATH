import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './context/AuthContext';
import Sidebar from './components/Sidebar';
import TopBar from './components/TopBar';

// Pages
import Login from './pages/Login';
import DashboardHome from './pages/DashboardHome';
import SOSMonitoring from './pages/SOSMonitoring';
import VarkariManagement from './pages/VarkariManagement';
import VolunteerManagement from './pages/VolunteerManagement';
import MissingPersons from './pages/MissingPersons';
import MedicalCamps from './pages/MedicalCamps';
import Medicines from './pages/Medicines';
import FoodWaterPoints from './pages/FoodWaterPoints';
import LiveWariMap from './pages/LiveWariMap';
import WeatherRisk from './pages/WeatherRisk';
import NotificationsCenter from './pages/NotificationsCenter';
import ReportsAnalytics from './pages/ReportsAnalytics';
import AdminManagement from './pages/AdminManagement';
import SettingsPage from './pages/Settings';

function ProtectedLayout() {
  const { isAuthenticated } = useAuth();

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-100 via-orange-50/30 to-slate-200/60 text-slate-900 flex relative">
      {/* Sidebar Navigation */}
      <Sidebar />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0 transition-all duration-300 pl-64">
        <TopBar />
        <main className="flex-1 p-6 overflow-y-auto">
          <Routes>
            <Route path="/" element={<DashboardHome />} />
            <Route path="/varkaris" element={<VarkariManagement />} />
            <Route path="/volunteers" element={<VolunteerManagement />} />
            <Route path="/sos" element={<SOSMonitoring />} />
            <Route path="/missing-persons" element={<MissingPersons />} />
            <Route path="/medical-camps" element={<MedicalCamps />} />
            <Route path="/medicines" element={<Medicines />} />
            <Route path="/food-water" element={<FoodWaterPoints />} />
            <Route path="/live-map" element={<LiveWariMap />} />
            <Route path="/weather-risk" element={<WeatherRisk />} />
            <Route path="/notifications" element={<NotificationsCenter />} />
            <Route path="/reports" element={<ReportsAnalytics />} />
            <Route path="/admin-mgmt" element={<AdminManagement />} />
            <Route path="/settings" element={<SettingsPage />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </main>
      </div>
    </div>
  );
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/*" element={<ProtectedLayout />} />
    </Routes>
  );
}
