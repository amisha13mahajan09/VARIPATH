import React, { useState, useEffect } from 'react';
import { BarChart3, Download, Calendar, TrendingUp, PieChart, RefreshCw } from 'lucide-react';
import { getAnalyticsReports } from '../services/api';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  PieChart as RePieChart,
  Pie,
  Cell,
  Legend
} from 'recharts';

const COLORS = ['#EA580C', '#2563EB', '#059669', '#E11D48', '#7C3AED'];

export default function ReportsAnalytics() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState('7d');

  useEffect(() => {
    fetchAnalyticsData();
  }, []);

  const fetchAnalyticsData = async () => {
    setLoading(true);
    try {
      const res = await getAnalyticsReports();
      if (res.success) {
        setData(res.data);
      }
    } catch (err) {
      console.error('Fetch analytics error:', err);
    } finally {
      setLoading(false);
    }
  };

  const exportCSV = () => {
    if (!data) return;
    const csvRows = [
      ['Metric', 'Value'],
      ['Active Missing Persons', data.missing_resolution?.active || 0],
      ['Resolved Missing Persons', data.missing_resolution?.resolved || 0],
      ['Missing Person Resolution Rate', data.missing_resolution?.resolution_rate || '0%'],
    ];

    const csvContent = 'data:text/csv;charset=utf-8,' + csvRows.map((e) => e.join(',')).join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `VariPath_Wari_Report_${dateRange}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 clean-card p-6 bg-white border-slate-200">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-2xl bg-purple-50 text-purple-600 border border-purple-200">
            <BarChart3 className="w-7 h-7" />
          </div>
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
              Reports & Operational Analytics
            </h2>
            <p className="text-xs text-slate-500 mt-0.5 font-medium">
              Statistical trends, SOS response rates, Varkari demographic metrics, and medical consumption
            </p>
          </div>
        </div>

        <div className="flex items-center space-x-3">
          <button
            onClick={exportCSV}
            className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs flex items-center gap-1.5 shadow-xs transition-colors"
          >
            <Download className="w-4 h-4" /> Export CSV Report
          </button>
          <button
            onClick={fetchAnalyticsData}
            className="p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 transition-colors"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Date Range Selector */}
      <div className="clean-card p-3 flex items-center space-x-2 text-xs">
        <span className="text-slate-500 font-semibold flex items-center gap-1">
          <Calendar className="w-4 h-4 text-orange-600" /> Filter Window:
        </span>
        {['today', '7d', '30d', 'custom'].map((range) => (
          <button
            key={range}
            onClick={() => setDateRange(range)}
            className={`px-3 py-1.5 rounded-xl font-bold uppercase transition-all ${
              dateRange === range
                ? 'bg-orange-600 text-white shadow-xs'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            {range === 'today' ? 'Today' : range === '7d' ? 'Last 7 Days' : range === '30d' ? 'Last 30 Days' : 'Custom Range'}
          </button>
        ))}
      </div>

      {/* Recharts Analytics Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* SOS Resolution Trends Bar Chart */}
        <div className="clean-card p-5 space-y-3">
          <h3 className="font-bold text-slate-900 text-base flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-orange-600" /> Daily SOS Incident & Resolution Trend
          </h3>
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data?.sos_trend || []}>
                <XAxis dataKey="day" stroke="#64748B" fontSize={12} />
                <YAxis stroke="#64748B" fontSize={12} />
                <Tooltip contentStyle={{ backgroundColor: '#FFFFFF', borderColor: '#E2E8F0', borderRadius: '8px', color: '#0F172A' }} />
                <Bar dataKey="total" fill="#E11D48" name="Total SOS Alerts" radius={[4, 4, 0, 0]} />
                <Bar dataKey="resolved" fill="#059669" name="Resolved Cases" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Varkari Demographics Pie Chart */}
        <div className="clean-card p-5 space-y-3">
          <h3 className="font-bold text-slate-900 text-base flex items-center gap-2">
            <PieChart className="w-5 h-5 text-amber-600" /> Varkari Pilgrim Age Demographics
          </h3>
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <RePieChart>
                <Pie
                  data={data?.demographics || []}
                  dataKey="count"
                  nameKey="age_group"
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  label
                >
                  {(data?.demographics || []).map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip contentStyle={{ backgroundColor: '#FFFFFF', borderColor: '#E2E8F0', borderRadius: '8px', color: '#0F172A' }} />
                <Legend />
              </RePieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
}
