import React, { useState, useEffect } from 'react';
import { Pill, AlertTriangle, CheckCircle2, Edit, RefreshCw } from 'lucide-react';
import { getMedicines, updateMedicineStock } from '../services/api';

export default function Medicines() {
  const [medicines, setMedicines] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editingItem, setEditingItem] = useState(null);
  const [newQty, setNewQty] = useState('');

  useEffect(() => {
    fetchMedicinesList();
  }, []);

  const fetchMedicinesList = async () => {
    setLoading(true);
    try {
      const res = await getMedicines();
      if (res.success) {
        setMedicines(res.data || []);
      }
    } catch (err) {
      console.error('Fetch medicines error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateStock = async (itemId) => {
    if (newQty === '' || isNaN(newQty)) return;
    try {
      const res = await updateMedicineStock(itemId, parseInt(newQty));
      if (res.success) {
        setEditingItem(null);
        fetchMedicinesList();
      }
    } catch (err) {
      alert('Failed to update stock');
    }
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 clean-card p-6 bg-white border-slate-200">
        <div className="flex items-center space-x-3">
          <div className="p-3 rounded-2xl bg-purple-50 text-purple-600 border border-purple-200">
            <Pill className="w-7 h-7" />
          </div>
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
              Medicine Stock & Emergency Supplies
            </h2>
            <p className="text-xs text-slate-500 mt-0.5 font-medium">
              Live stock inventory tracking across all Wari medical posts (ORS, First Aid, IV Sets)
            </p>
          </div>
        </div>

        <button
          onClick={fetchMedicinesList}
          className="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs flex items-center gap-2 transition-colors"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} /> Refresh Inventory
        </button>
      </div>

      {/* Inventory Table */}
      <div className="clean-card overflow-hidden border border-slate-200">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-700">
            <thead className="bg-slate-50 text-slate-500 uppercase font-bold border-b border-slate-200">
              <tr>
                <th className="py-3.5 px-4">Item ID</th>
                <th className="py-3.5 px-4">Medicine / Supply Name</th>
                <th className="py-3.5 px-4">Category</th>
                <th className="py-3.5 px-4">Medical Camp Location</th>
                <th className="py-3.5 px-4">Available Quantity</th>
                <th className="py-3.5 px-4">Stock Status</th>
                <th className="py-3.5 px-4 text-right">Quick Stock Update</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-slate-400 font-medium">
                    Loading medicine inventory...
                  </td>
                </tr>
              ) : medicines.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-slate-400 font-medium">
                    No medicine inventory records found.
                  </td>
                </tr>
              ) : (
                medicines.map((m) => {
                  const isCritical = m.status === 'Critical' || m.status === 'Out of Stock';
                  const isLow = m.status === 'Low Stock';

                  return (
                    <tr key={m.item_id} className="hover:bg-slate-50 transition-colors">
                      <td className="py-3.5 px-4 font-mono font-bold text-orange-600">{m.item_id}</td>
                      <td className="py-3.5 px-4 font-bold text-slate-900">{m.name}</td>
                      <td className="py-3.5 px-4 text-slate-500">{m.category}</td>
                      <td className="py-3.5 px-4 text-slate-700">{m.camp_name || m.camp_id}</td>
                      <td className="py-3.5 px-4 font-bold text-sm text-slate-900">
                        {m.available_quantity} / {m.total_capacity} {m.unit}
                      </td>
                      <td className="py-3.5 px-4">
                        <span className={`px-2.5 py-0.5 rounded-full font-bold text-[10px] border ${
                          isCritical
                            ? 'bg-rose-50 text-rose-700 border-rose-200'
                            : isLow
                            ? 'bg-amber-50 text-amber-700 border-amber-200'
                            : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                        }`}>
                          {m.status}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 text-right">
                        {editingItem === m.item_id ? (
                          <div className="flex items-center justify-end space-x-2">
                            <input
                              type="number"
                              value={newQty}
                              onChange={(e) => setNewQty(e.target.value)}
                              placeholder="Qty"
                              className="w-20 px-2 py-1 rounded bg-slate-50 border border-slate-200 text-slate-900 text-xs font-mono"
                            />
                            <button
                              onClick={() => handleUpdateStock(m.item_id)}
                              className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded text-xs"
                            >
                              Save
                            </button>
                            <button
                              onClick={() => setEditingItem(null)}
                              className="px-2 py-1 bg-slate-100 text-slate-600 rounded text-xs"
                            >
                              Cancel
                            </button>
                          </div>
                        ) : (
                          <button
                            onClick={() => {
                              setEditingItem(m.item_id);
                              setNewQty(m.available_quantity);
                            }}
                            className="px-2.5 py-1 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs inline-flex items-center gap-1 transition-colors"
                          >
                            <Edit className="w-3.5 h-3.5" /> Edit Stock
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
