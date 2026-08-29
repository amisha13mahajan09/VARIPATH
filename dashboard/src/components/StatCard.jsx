import React from 'react';
import { ArrowUpRight } from 'lucide-react';
import { Link } from 'react-router-dom';

export default function StatCard({
  title,
  count,
  subtitle,
  icon: Icon,
  color = 'orange',
  pulse = false,
  linkTo,
  badgeText
}) {
  const colorMap = {
    orange: { bg: 'bg-orange-50', text: 'text-orange-600', border: 'border-orange-200' },
    emerald: { bg: 'bg-emerald-50', text: 'text-emerald-600', border: 'border-emerald-200' },
    red: { bg: 'bg-rose-50', text: 'text-rose-600', border: 'border-rose-200' },
    amber: { bg: 'bg-amber-50', text: 'text-amber-600', border: 'border-amber-200' },
    blue: { bg: 'bg-blue-50', text: 'text-blue-600', border: 'border-blue-200' },
    purple: { bg: 'bg-purple-50', text: 'text-purple-600', border: 'border-purple-200' },
  };

  const scheme = colorMap[color] || colorMap.orange;

  const content = (
    <div className={`clean-card-interactive p-5 flex flex-col justify-between h-full relative overflow-hidden ${pulse ? 'ring-2 ring-rose-500/50' : ''}`}>
      <div className="flex items-start justify-between">
        <div>
          <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">{title}</span>
          <h3 className="text-3xl font-extrabold text-slate-900 mt-1 tracking-tight">{count}</h3>
        </div>

        <div className={`p-3 rounded-xl ${scheme.bg} ${scheme.text} border ${scheme.border}`}>
          {Icon && <Icon className="w-5 h-5" />}
        </div>
      </div>

      <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between">
        <p className="text-xs text-slate-500 font-medium truncate max-w-[180px]">{subtitle}</p>
        
        {badgeText && (
          <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${scheme.bg} ${scheme.text} ${scheme.border}`}>
            {badgeText}
          </span>
        )}
      </div>
    </div>
  );

  return linkTo ? <Link to={linkTo} className="block h-full">{content}</Link> : content;
}
