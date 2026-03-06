import React, { useState, useEffect } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, PieChart, Pie, Cell } from 'recharts';
import { getAnalytics, AnalyticsResponse } from '../api';

const COLORS = ['#c86601', '#e08e00', '#f5c645', '#ffeeba', '#fed7aa'];

const fmt = (n: number) =>
  new Intl.NumberFormat('vi-VN').format(Math.round(n)) + 'đ';

export const Analytics: React.FC = () => {
  const [period, setPeriod] = useState<7 | 30 | 365>(7);
  const [data, setData] = useState<AnalyticsResponse | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    getAnalytics(period)
      .then(setData)
      .catch(() => setData(null))
      .finally(() => setLoading(false));
  }, [period]);

  const periodLabel = period === 7 ? '7 ngày qua' : period === 30 ? '30 ngày qua' : 'Năm nay';

  const chartData = data?.dailyRevenue.map(d => ({
    name: d.day.slice(5),
    revenue: Number(d.revenue) || 0,
    orders: d.orders,
  })) ?? [];

  const statusData = data
    ? Object.entries(data.statusBreakdown).map(([k, v]) => ({ name: k, value: v }))
    : [];

  const s = data?.summary;

  return (
    <div className="p-4 md:p-8 max-w-7xl mx-auto space-y-8">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 tracking-tight">Báo cáo & Phân tích</h1>
          <p className="text-gray-500 text-sm mt-1">Phân tích sâu hiệu quả kinh doanh của bạn</p>
        </div>
        <select
          value={period}
          onChange={e => setPeriod(Number(e.target.value) as 7 | 30 | 365)}
          className="bg-white border border-gray-200 text-gray-700 px-4 py-2 rounded-lg text-sm font-semibold shadow-sm outline-none focus:border-primary"
        >
          <option value={7}>7 ngày qua</option>
          <option value={30}>30 ngày qua</option>
          <option value={365}>Năm nay</option>
        </select>
      </div>

      {loading && (
        <div className="flex items-center justify-center h-64">
          <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
        </div>
      )}

      {!loading && (
        <>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {[
              { label: 'Tổng doanh thu', value: fmt(s?.totalRevenue ?? 0) },
              { label: 'Tổng đơn hàng', value: String(s?.totalOrders ?? 0) },
              { label: 'Giá trị TB đơn', value: fmt(s?.avgOrderValue ?? 0) },
              { label: 'Đơn huỷ', value: String(s?.cancelledOrders ?? 0) },
            ].map(kpi => (
              <div key={kpi.label} className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm">
                <h3 className="text-gray-500 font-semibold text-xs uppercase tracking-wider mb-2">{kpi.label}</h3>
                <p className="text-2xl font-bold text-gray-900">{kpi.value}</p>
              </div>
            ))}
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 bg-white p-6 rounded-2xl border border-gray-200 shadow-sm">
              <h3 className="font-semibold text-lg mb-6">Doanh thu ({periodLabel})</h3>
              {chartData.length === 0 ? (
                <div className="h-64 flex items-center justify-center text-gray-400 text-sm">Chưa có dữ liệu cho kỳ này</div>
              ) : (
                <div className="h-64">
                  <ResponsiveContainer width="100%" height={256}>
                    <AreaChart data={chartData} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
                      <defs>
                        <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#c86601" stopOpacity={0.8}/>
                          <stop offset="95%" stopColor="#c86601" stopOpacity={0}/>
                        </linearGradient>
                      </defs>
                      <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: '#9ca3af', fontSize: 11}} dy={10} />
                      <YAxis axisLine={false} tickLine={false} tick={{fill: '#9ca3af', fontSize: 11}} tickFormatter={v => v >= 1000000 ? (v/1000000).toFixed(1)+'M' : v >= 1000 ? (v/1000).toFixed(0)+'k' : String(v)} />
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0"/>
                      <Tooltip formatter={(v: any) => [fmt(Number(v)), 'Doanh thu']} contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}} />
                      <Area type="monotone" dataKey="revenue" stroke="#c86601" fillOpacity={1} fill="url(#colorRevenue)" />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              )}
            </div>
            <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm flex flex-col">
              <h3 className="font-semibold text-lg mb-4">Trạng thái Đơn hàng</h3>
              {statusData.length === 0 ? (
                <div className="flex-1 flex items-center justify-center text-gray-400 text-sm">Chưa có dữ liệu</div>
              ) : (
                <>
                  <div className="h-48 flex-1">
                    <ResponsiveContainer width="100%" height={192}>
                      <PieChart>
                        <Pie data={statusData} cx="50%" cy="50%" innerRadius={45} outerRadius={70} paddingAngle={4} dataKey="value">
                          {statusData.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                        </Pie>
                        <Tooltip />
                      </PieChart>
                    </ResponsiveContainer>
                  </div>
                  <div className="space-y-1.5 mt-3">
                    {statusData.slice(0, 5).map((entry, i) => (
                      <div key={i} className="flex items-center justify-between text-xs text-gray-600">
                        <div className="flex items-center gap-1.5">
                          <div className="w-2.5 h-2.5 rounded-full shrink-0" style={{backgroundColor: COLORS[i % COLORS.length]}}></div>
                          <span className="truncate max-w-[120px]">{entry.name}</span>
                        </div>
                        <span className="font-semibold">{entry.value}</span>
                      </div>
                    ))}
                  </div>
                </>
              )}
            </div>
          </div>

          {data && data.topItems.length > 0 && (
            <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm">
              <h3 className="font-semibold text-lg mb-6">Top Món bán chạy ({periodLabel})</h3>
              <div className="space-y-3">
                {data.topItems.map((item, i) => {
                  const maxQty = data.topItems[0].qty;
                  const pct = maxQty > 0 ? Math.round((item.qty / maxQty) * 100) : 0;
                  return (
                    <div key={i} className="flex items-center gap-4">
                      <div className="w-6 text-center text-sm font-bold text-gray-400">{i + 1}</div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-sm font-semibold text-gray-900 truncate">{item.name}</span>
                          <span className="text-sm text-gray-500 ml-2 shrink-0">{item.qty} phần · {fmt(Number(item.revenue))}</span>
                        </div>
                        <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                          <div className="h-full bg-primary rounded-full" style={{width: `${pct}%`}}></div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {chartData.length > 0 && (
            <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm">
              <h3 className="font-semibold text-lg mb-6">Số đơn hàng mỗi ngày</h3>
              <div className="h-64">
                <ResponsiveContainer width="100%" height={256}>
                  <BarChart data={chartData}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
                    <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: '#9ca3af', fontSize: 11}} dy={10} />
                    <YAxis axisLine={false} tickLine={false} tick={{fill: '#9ca3af', fontSize: 11}} />
                    <Tooltip cursor={{fill: '#f8f7f5'}} contentStyle={{borderRadius: '8px', border: 'none'}} />
                    <Bar dataKey="orders" name="Đơn hàng" fill="#c86601" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
};
