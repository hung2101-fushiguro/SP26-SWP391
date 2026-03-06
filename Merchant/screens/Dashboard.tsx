import React, { useEffect, useState } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { getDashboard, DashboardStats, getShopName } from '../api';

const DAY_LABELS = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

export const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    getDashboard()
      .then(setStats)
      .catch(() => setError('Không thể tải dữ liệu. Vui lòng thử lại.'))
      .finally(() => setLoading(false));
  }, []);

  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(value);

  const chartData = stats
    ? (stats.weeklyRevenue || []).map((rev, i) => ({
      name: DAY_LABELS[i] ?? `N${i + 1}`,
      sales: rev,
      orders: (stats.weeklyOrders || [])[i] ?? 0,
    }))
    : DAY_LABELS.map((name) => ({ name, sales: 0, orders: 0 }));

  if (loading) {
    return (
      <div className= "flex items-center justify-center h-full" >
      <span className="material-symbols-outlined animate-spin text-4xl text-primary" > progress_activity </span>
        </div>
    );
  }

if (error) {
  return (
    <div className= "flex flex-col items-center justify-center h-full gap-3" >
    <span className="material-symbols-outlined text-4xl text-red-400" > error </span>
      < p className = "text-gray-500 font-medium" > { error } </p>
        < button onClick = {() => window.location.reload()
} className = "text-primary font-semibold hover:underline" > Tải lại </button>
  </div>
    );
  }

const shopName = getShopName() || 'ClickEat Merchant';
const avgOrder = stats && stats.todayOrders > 0
  ? stats.todayRevenue / stats.todayOrders
  : 0;

const statusLabel: Record<string, { text: string; color: string }> = {
  CREATED: { text: 'Mới', color: 'bg-blue-100 text-blue-700' },
  PAID: { text: 'Mới', color: 'bg-blue-100 text-blue-700' },
  MERCHANT_ACCEPTED: { text: 'Đang nấu', color: 'bg-yellow-100 text-yellow-700' },
  PREPARING: { text: 'Đang nấu', color: 'bg-yellow-100 text-yellow-700' },
  READY_FOR_PICKUP: { text: 'Sẵn sàng', color: 'bg-green-100 text-green-700' },
  DELIVERING: { text: 'Đang giao', color: 'bg-purple-100 text-purple-700' },
  DELIVERED: { text: 'Hoàn tất', color: 'bg-gray-100 text-gray-700' },
  CANCELLED: { text: 'Hủy', color: 'bg-red-100 text-red-700' },
  FAILED: { text: 'Thất bại', color: 'bg-red-100 text-red-700' },
};

return (
  <div className= "p-4 md:p-8 max-w-7xl mx-auto space-y-6 md:space-y-8" >
  <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4" >
    <div>
    <h1 className="text-2xl md:text-3xl font-bold text-gray-900 tracking-tight" > Chào buổi sáng, { shopName }! 👋</h1>
      < p className = "text-gray-500 mt-1 text-sm md:text-base" > Đây là tình hình kinh doanh hôm nay của bạn.</p>
        </div>
        </div>

        < div className = "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6" >
        {
          [
          { label: 'Doanh thu hôm nay', value: formatCurrency(stats?.todayRevenue ?? 0), icon: 'payments', color: 'text-primary', bg: 'bg-orange-50' },
          { label: 'Đơn hàng hôm nay', value: String(stats?.todayOrders ?? 0), icon: 'receipt_long', color: 'text-blue-600', bg: 'bg-blue-50' },
          { label: 'Giá trị TB đơn', value: formatCurrency(avgOrder), icon: 'data_usage', color: 'text-purple-600', bg: 'bg-purple-50' },
          { label: 'Đánh giá TB', value: stats?.avgRating != null ? stats.avgRating.toFixed(1) : '—', icon: 'star', color: 'text-yellow-500', bg: 'bg-yellow-50' },
        ].map((stat, i) => (
            <div key= { i } className = "bg-white p-6 rounded-2xl border border-gray-200 shadow-sm hover:shadow-md transition-all group" >
            <div className="flex justify-between items-start mb-4" >
          <div className={`p-3 rounded-xl ${stat.bg} ${stat.color} group-hover:scale-110 transition-transform`} >
          <span className="material-symbols-outlined" > { stat.icon } </span>
            </div>
            </div>
            < p className = "text-gray-500 text-sm font-semibold mb-1" > { stat.label } </p>
              < h3 className = "text-2xl font-bold text-gray-900" > { stat.value } </h3>
                </div>
        ))}
</div>

  < div className = "grid grid-cols-1 lg:grid-cols-3 gap-6 md:gap-8" >
    <div className="lg:col-span-2 bg-white p-6 rounded-2xl border border-gray-200 shadow-sm flex flex-col" >
      <div className="flex justify-between items-center mb-6" >
        <h3 className="font-semibold text-lg text-gray-900" > Biểu đồ Doanh thu(7 ngày) </h3>
          </div>
          < div className = "h-80 w-full flex-1" >
            <ResponsiveContainer width="100%" height={300} >
              <AreaChart data={ chartData } margin = {{ top: 10, right: 10, left: 0, bottom: 0 }}>
                <defs>
                <linearGradient id="colorSales" x1 = "0" y1 = "0" x2 = "0" y2 = "1" >
                  <stop offset="5%" stopColor = "#c86601" stopOpacity = { 0.2} />
                    <stop offset="95%" stopColor = "#c86601" stopOpacity = { 0} />
                      </linearGradient>
                      </defs>
                      < XAxis dataKey = "name" axisLine = { false} tickLine = { false} tick = {{ fill: '#9ca3af', fontSize: 12 }} dy = { 10} />
                        <YAxis axisLine={ false } tickLine = { false} tick = {{ fill: '#9ca3af', fontSize: 12 }} tickFormatter = {(v) => `${(v / 1000000).toFixed(1)}M`} />
                          < CartesianGrid strokeDasharray = "3 3" vertical = { false} stroke = "#f0f0f0" />
                            <Tooltip contentStyle={ { borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' } } formatter = {(value: number) => [formatCurrency(value), 'Doanh thu']} />
                              < Area type = "monotone" dataKey = "sales" stroke = "#c86601" strokeWidth = { 3} fillOpacity = { 1} fill = "url(#colorSales)" />
                                </AreaChart>
                                </ResponsiveContainer>
                                </div>
                                </div>

                                < div className = "space-y-6" >
                                  <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm" >
                                    <h3 className="font-semibold text-lg mb-4 text-gray-900" > Món bán chạy </h3>
{
  stats?.topItems?.length ? (
    <div className= "space-y-4" >
    {
      stats.topItems.slice(0, 5).map((item, i) => (
        <div key= { i } className = "flex items-center justify-between group" >
        <div className="flex items-center gap-3" >
      <span className={`text-xs font-semibold w-6 h-6 rounded flex items-center justify-center ${i === 0 ? 'bg-yellow-100 text-yellow-700' : 'bg-gray-100 text-gray-500'}`} > { i + 1} </span>
        < span className = "font-medium text-gray-700 text-sm" > { item.name } </span>
          </div>
          < p className = "font-semibold text-gray-900 text-sm" > { item.orders } đơn </p>
            </div>
                ))}
</div>
            ) : (
  <p className= "text-gray-400 text-sm text-center py-4" > Chưa có dữ liệu </p>
            )}
</div>

  < div className = "bg-gradient-to-br from-primary to-orange-600 p-6 rounded-2xl shadow-lg shadow-primary/30 text-white relative overflow-hidden group" >
    <div className="relative z-10" >
      <div className="flex items-center gap-2 mb-2" >
        <span className="relative flex h-2.5 w-2.5" >
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75" > </span>
            < span className = "relative inline-flex rounded-full h-2.5 w-2.5 bg-white" > </span>
              </span>
              < span className = "text-xs font-semibold uppercase tracking-wider opacity-90" > Hoạt động trực tiếp </span>
                </div>
                < h3 className = "text-2xl font-bold mb-1" > { stats?.pendingOrders ?? 0} Đơn hàng </h3>
                  < p className = "text-sm opacity-90" > Đang chờ xác nhận từ bếp </p>
                    </div>
                    < span className = "material-symbols-outlined absolute -right-6 -bottom-6 text-[140px] opacity-10 group-hover:rotate-12 transition-transform duration-500" > cooking </span>
                      </div>
                      </div>
                      </div>

                      < div className = "bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden" >
                        <div className="p-6 border-b border-gray-100 bg-gray-50/50" >
                          <h3 className="font-semibold text-lg text-gray-900" > Đơn hàng gần đây </h3>
                            </div>
                            < div className = "overflow-x-auto" >
                              <table className="w-full text-left min-w-[600px]" >
                                <thead className="bg-gray-50 text-gray-500 text-xs uppercase font-semibold" >
                                  <tr>
                                  <th className="px-6 py-4" > Mã đơn </th>
                                    < th className = "px-6 py-4" > Khách hàng </th>
                                      < th className = "px-6 py-4" > Tổng tiền </th>
                                        < th className = "px-6 py-4" > Trạng thái </th>
                                          < th className = "px-6 py-4" > Thời gian </th>
                                            </tr>
                                            </thead>
                                            < tbody className = "divide-y divide-gray-100 text-sm" >
                                            {
                                              stats?.recentOrders?.length?(
                                                stats.recentOrders.map((order) => {
                                                  const s = statusLabel[order.status] ?? { text: order.status, color: 'bg-gray-100 text-gray-700' };
                                                  return (
                                                    <tr key= { order.id } className = "hover:bg-gray-50/50 transition-colors" >
                                                      <td className="px-6 py-4 font-mono font-medium text-gray-500" > { order.orderCode } </td>
                                                        < td className = "px-6 py-4 font-semibold text-gray-900" > { order.customerName } </td>
                                                          < td className = "px-6 py-4 font-semibold text-gray-900" > { formatCurrency(order.total)
                                            } </td>
                                              < td className = "px-6 py-4" > <span className={ `px-2.5 py-1 rounded-md text-xs font-semibold ${s.color}` }> { s.text } < /span></td >
                                                <td className="px-6 py-4 text-gray-400 text-xs" > { new Date(order.createdAt).toLocaleString('vi-VN') } </td>
                                                  </tr>
                  );
                })
              ) : (
  <tr><td colSpan= { 5} className = "px-6 py-8 text-center text-gray-400" > Chưa có đơn hàng < /td></tr >
              )}
</tbody>
  </table>
  </div>
  </div>
  </div>
  );
};
