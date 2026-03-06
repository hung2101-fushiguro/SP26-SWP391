import React, { useState, useEffect, useCallback } from 'react';
import { Screen } from '../types';
import { getOrders, getOrderById, updateOrderStatus, Order as ApiOrder } from '../api';

interface OrderManagementProps {
  onNavigate: (screen: Screen, params?: any) => void;
  view: 'LIST' | 'DETAIL';
  params?: any;
}

interface OrderItem {
  qty: number;
  name: string;
  price: number;
  notes?: string;
}

interface Order {
  id: string;         // orderCode for display
  rawId: number;      // DB id for API calls
  user: string;
  time: string;
  items: OrderItem[];
  total: number;
  status: 'New' | 'Preparing' | 'Ready' | 'Completed' | 'Cancelled';
  isUrgent?: boolean;
  phone?: string;
  address?: string;
}

const BE_TO_UI: Record<string, Order['status']> = {
  CREATED: 'New',
  PAID: 'New',
  MERCHANT_ACCEPTED: 'Preparing',
  PREPARING: 'Preparing',
  READY_FOR_PICKUP: 'Ready',
  PICKED_UP: 'Ready',
  DELIVERING: 'Ready',
  DELIVERED: 'Completed',
  CANCELLED: 'Cancelled',
  MERCHANT_REJECTED: 'Cancelled',
  FAILED: 'Cancelled',
};

// Maps the *next* UI status (what the button targets) → backend status value
const UI_TO_BE: Record<string, string> = {
  Preparing: 'MERCHANT_ACCEPTED',    // "Chấp nhận" / "Nhận đơn & Nấu"
  Ready:     'READY_FOR_PICKUP',     // "Báo Sẵn sàng"
  Cancelled: 'CANCELLED',            // "Từ chối"
};

function mapOrder(o: ApiOrder): Order {
  const status = BE_TO_UI[o.orderStatus] ?? 'New';
  const createdMs = new Date(o.createdAt).getTime();
  const diffMin = Math.round((Date.now() - createdMs) / 60000);
  const timeStr = diffMin < 1 ? 'Vừa xong' : diffMin < 60 ? `${diffMin} phút trước` : new Date(o.createdAt).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
  return {
    id: o.orderCode,
    rawId: o.id,
    user: o.receiverName,
    phone: o.receiverPhone,
    address: o.deliveryAddressLine,
    time: timeStr,
    items: (o.items || []).map(it => ({ qty: it.quantity, name: it.itemNameSnapshot, price: it.unitPriceSnapshot ?? 0 })),
    total: o.totalAmount,
    status,
    isUrgent: status === 'New' && diffMin < 5,
  };
}

export const OrderManagement: React.FC<OrderManagementProps> = ({ onNavigate, view, params }) => {
  const [activeTab, setActiveTab] = useState('Tất cả');
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [detailOrder, setDetailOrder] = useState<Order | null>(null);
  const [updating, setUpdating] = useState(false);

  const loadOrders = useCallback(async () => {
    setLoading(true);
    try {
      const res = await getOrders(undefined, 1, 50);
      setOrders((res.items || []).map(mapOrder));
    } catch {
      setOrders([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (view === 'LIST') {
      loadOrders();
    } else if (view === 'DETAIL' && params?.orderId) {
      setLoading(true);
      getOrderById(Number(params.orderId))
        .then(o => setDetailOrder(mapOrder(o)))
        .catch(() => setDetailOrder(null))
        .finally(() => setLoading(false));
    }
  }, [view, params?.orderId, loadOrders]);

  const statusMap = {
    'New': { label: 'Mới', color: 'bg-blue-100 text-blue-700 border-blue-200' },
    'Preparing': { label: 'Đang chuẩn bị', color: 'bg-yellow-100 text-yellow-700 border-yellow-200' },
    'Ready': { label: 'Sẵn sàng', color: 'bg-green-100 text-green-700 border-green-200' },
    'Completed': { label: 'Hoàn tất', color: 'bg-gray-100 text-gray-600 border-gray-200' },
    'Cancelled': { label: 'Đã hủy', color: 'bg-red-100 text-red-700 border-red-200' }
  };

  const tabMap: Record<string, string> = {
    'Tất cả': 'All',
    'Mới': 'New',
    'Đang chuẩn bị': 'Preparing',
    'Sẵn sàng': 'Ready',
    'Hoàn tất': 'Completed'
  };

  const handleStatusChange = async (rawId: number, uiStatus: Order['status']) => {
    setUpdating(true);
    try {
      await updateOrderStatus(rawId, UI_TO_BE[uiStatus]);
      if (view === 'LIST') {
        setOrders(prev => prev.map(o => o.rawId === rawId ? { ...o, status: uiStatus } : o));
      } else if (detailOrder && detailOrder.rawId === rawId) {
        setDetailOrder({ ...detailOrder, status: uiStatus });
      }
    } catch (err) {
      console.error('Failed to update status', err);
    } finally {
      setUpdating(false);
    }
  };

  const filteredOrders = activeTab === 'Tất cả'
    ? orders.filter(o => o.status !== 'Cancelled' && o.status !== 'Completed')
    : orders.filter(o => o.status === tabMap[activeTab]);

  const formatPrice = (price: number) =>
    new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price);

  // ---------------- DETAIL VIEW ----------------
  if (view === 'DETAIL') {
    if (loading) return <div className="flex items-center justify-center h-full" > <span className="material-symbols-outlined animate-spin text-4xl text-primary" > progress_activity < /span></div >;
    if (!detailOrder) return <div className="flex flex-col items-center justify-center h-full gap-3" > <p className="text-gray-500" > Không tìm thấy đơn hàng.< /p><button onClick={() => onNavigate(Screen.ORDERS)} className="text-primary font-semibold hover:underline">Quay lại</button > </div>;

    const activeOrder = detailOrder;
    const statusInfo = statusMap[activeOrder.status];

    return (
      <div className= "p-4 md:p-8 max-w-7xl mx-auto flex flex-col min-h-[calc(100vh-4rem)]" >
      <div className="md:hidden flex items-center gap-2 mb-4 text-sm" >
        <button onClick={ () => onNavigate(Screen.ORDERS) } className = "text-gray-500" >
          <span className="material-symbols-outlined" > arrow_back </span>
            </button>
            < span className = "font-semibold text-gray-900" > { activeOrder.id } </span>
              </div>

              < div className = "grid grid-cols-1 lg:grid-cols-3 gap-8 h-full" >
                <div className="lg:col-span-1" >
                  <div className="bg-white rounded-none md:rounded-2xl shadow-xl overflow-hidden border-t-8 border-primary relative" >
                    <div className="p-6 pb-10 bg-white" >
                      <div className="text-center mb-6 border-b border-dashed border-gray-200 pb-6" >
                        <h2 className="text-3xl font-bold text-gray-900 mb-1" > { activeOrder.id } </h2>
                          < p className = "text-gray-500 font-medium" > { activeOrder.time } </p>
                            < div className = {`inline-block mt-3 px-3 py-1 rounded-full text-xs font-semibold uppercase border ${statusInfo.color}`
  }>
    { statusInfo.label }
    </div>
    </div>

    < div className = "space-y-6" >
    {
      activeOrder.items.map((item, i) => (
        <div key= { i } className = "flex justify-between items-start" >
        <div className="flex gap-3" >
      <span className="font-bold text-lg w-8 h-8 flex items-center justify-center bg-gray-100 rounded text-gray-800" > { item.qty } </span>
      < div >
      <p className="font-semibold text-gray-900 text-lg leading-tight" > { item.name } </p>
                          { item.notes && <p className="text-red-500 font-semibold text-sm italic mt-1"> Note: { item.notes } </p>}
      </div>
      </div>
      < span className = "font-medium text-gray-600" > { formatPrice(item.price * item.qty) } </span>
        </div>
                  ))}
</div>

  < div className = "mt-8 pt-6 border-t border-dashed border-gray-300 space-y-2" >
    <div className="flex justify-between items-end mt-2" >
      <span className="font-semibold text-xl text-gray-900" > Tổng cộng </span>
        < span className = "font-bold text-2xl text-primary" > { formatPrice(activeOrder.total) } </span>
          </div>
          </div>
          </div>
          </div>

          < div className = "mt-6 flex flex-col gap-3" >
          {
            activeOrder.status === 'New' && (
              <button disabled={ updating } onClick = {() => handleStatusChange(activeOrder.rawId, 'Preparing')}
className = "w-full py-4 bg-primary text-white font-semibold text-lg rounded-xl shadow-lg hover:bg-orange-600 disabled:opacity-60 transition-all flex items-center justify-center gap-2" >
  <span className="material-symbols-outlined" > cooking </span>
                  Nhận đơn & Nấu
  </button>
              )}
{
  activeOrder.status === 'Preparing' && (
    <button disabled={ updating } onClick = {() => handleStatusChange(activeOrder.rawId, 'Ready')
}
className = "w-full py-4 bg-green-600 text-white font-semibold text-lg rounded-xl shadow-lg hover:bg-green-700 disabled:opacity-60 transition-all flex items-center justify-center gap-2" >
  <span className="material-symbols-outlined" > check_circle </span>
                  Báo Sẵn sàng
  </button>
              )}
<button onClick={ () => onNavigate(Screen.REFUND) } className = "w-full py-3 bg-white border border-gray-300 text-gray-700 font-semibold rounded-xl hover:bg-red-50 hover:text-red-600 hover:border-red-200 transition-colors" >
  Hoàn tiền / Hủy món
    </button>
    </div>
    </div>

    < div className = "lg:col-span-2 space-y-6" >
      <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm" >
        <h3 className="font-semibold text-lg mb-4 text-gray-900" > Thông tin giao nhận </h3>
          < div className = "grid grid-cols-1 md:grid-cols-2 gap-6" >
            <div className="flex items-start gap-4 p-4 rounded-xl bg-gray-50 border border-gray-100" >
              <div className="w-12 h-12 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-semibold text-xl" >
                { activeOrder.user.charAt(0) }
                </div>
                < div className = "flex-1" >
                  <p className="text-xs font-semibold text-gray-500 uppercase" > Khách hàng </p>
                    < p className = "font-semibold text-gray-900 text-lg" > { activeOrder.user } </p>
{ activeOrder.phone && <p className="text-sm text-gray-500 mt-1" > { activeOrder.phone } </p> }
{ activeOrder.address && <p className="text-sm text-gray-400 mt-0.5 truncate" > { activeOrder.address } </p> }
<div className="flex gap-2 mt-3" >
  <button onClick={ () => onNavigate(Screen.CHAT, { chatId: activeOrder.rawId }) }
className = "flex-1 bg-white border border-gray-200 py-1.5 rounded-lg text-sm font-semibold text-primary hover:bg-primary hover:text-white transition-colors flex items-center justify-center gap-1" >
  <span className="material-symbols-outlined text-sm" > chat </span> Chat
    </button>
    </div>
    </div>
    </div>

    < div className = "flex items-center justify-center p-4 rounded-xl bg-gray-50 border border-dashed border-gray-300 text-gray-400" >
      <div className="text-center" >
        <span className="material-symbols-outlined text-3xl mb-1" > moped </span>
          < p className = "text-sm font-medium" > Đang tìm tài xế...</p>
            </div>
            </div>
            </div>
            </div>

            < div className = "bg-white p-6 rounded-2xl border border-gray-200 shadow-sm" >
              <h3 className="font-semibold text-lg mb-6" > Trạng thái đơn hàng </h3>
                < div className = "space-y-8 relative pl-2" >
                  <div className="absolute left-[19px] top-2 bottom-4 w-0.5 bg-gray-100" > </div>
{
  [
    { title: 'Giao hàng thành công', done: activeOrder.status === 'Completed', current: false },
    { title: 'Sẵn sàng lấy hàng', done: ['Completed'].includes(activeOrder.status), current: activeOrder.status === 'Ready' },
    { title: 'Đang chuẩn bị món', done: ['Ready', 'Completed'].includes(activeOrder.status), current: activeOrder.status === 'Preparing' },
    { title: 'Đặt hàng thành công', done: true, current: false },
  ].map((step, i) => (
    <div key= { i } className = "relative flex gap-4" >
    <div className={`w-10 h-10 rounded-full border-4 border-white flex items-center justify-center shrink-0 z-10 ${step.done ? 'bg-green-500' : step.current ? 'bg-primary animate-pulse' : 'bg-gray-200'}`}>
      { step.done && <span className="material-symbols-outlined text-white text-sm"> check </span> }
{ step.current && <span className="material-symbols-outlined text-white text-sm" > cooking </span> }
</div>
  < div className = {!step.done && !step.current ? 'opacity-50' : ''}>
    <p className="font-semibold text-gray-900" > { step.title } </p>
      </div>
      </div>
                ))}
</div>
  </div>
  </div>
  </div>
  </div>
    );
  }

// ---------------- LIST VIEW ----------------
return (
  <div className= "p-4 md:p-8 max-w-7xl mx-auto space-y-6" >
  <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4" >
    <div>
    <h1 className="text-2xl md:text-3xl font-bold text-gray-900 tracking-tight" > Quản lý Đơn hàng </h1>
      < p className = "text-gray-500 text-sm mt-1" > Trung tâm kiểm soát thời gian thực </p>
        </div>
        < div className = "flex gap-2" >
          <span className="bg-primary/10 text-primary px-4 py-2 rounded-full text-sm font-semibold border border-primary/20 flex items-center gap-2" >
            <span className="w-2 h-2 bg-primary rounded-full animate-pulse" > </span>
{ orders.filter(o => o.status === 'New').length } Đơn mới
  </span>
  < button onClick = { loadOrders } className = "p-2 rounded-full bg-white border border-gray-200 hover:bg-gray-50 transition-colors" title = "Làm mới" >
    <span className={ `material-symbols-outlined text-gray-500 ${loading ? 'animate-spin' : ''}` }> refresh </span>
      </button>
      </div>
      </div>

      < div className = "bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden" >
        <div className="flex border-b border-gray-200 overflow-x-auto no-scrollbar" >
        {
          ['Tất cả', 'Mới', 'Đang chuẩn bị', 'Sẵn sàng', 'Hoàn tất'].map((tab, i) => (
            <button key= { i } onClick = {() => setActiveTab(tab)}
className = {`flex-1 py-4 px-6 text-sm font-semibold whitespace-nowrap border-b-2 transition-colors ${activeTab === tab ? 'border-primary text-primary bg-orange-50/50' : 'border-transparent text-gray-500 hover:text-gray-900'}`}>
  { tab }
{ tab === 'Mới' && <span className="ml-2 bg-primary text-white text-[10px] px-1.5 py-0.5 rounded-full" > { orders.filter(o => o.status === 'New').length } </span> }
{ tab === 'Đang chuẩn bị' && <span className="ml-2 bg-gray-200 text-gray-700 text-[10px] px-1.5 py-0.5 rounded-full" > { orders.filter(o => o.status === 'Preparing').length } </span> }
</button>
          ))}
</div>

  < div className = "divide-y divide-gray-100" >
  {
    loading?(
            <div className = "p-12 text-center" >
        <span className="material-symbols-outlined animate-spin text-4xl text-primary"> progress_activity </span>
    </div>
          ) : filteredOrders.length === 0 ? (
  <div className= "p-12 text-center text-gray-400" >
  <span className="material-symbols-outlined text-4xl mb-2" > inbox </span>
    < p > Không có đơn hàng nào trong mục này </p>
      </div>
          ) : (
  filteredOrders.map((order, i) => (
    <div key= { i } className = "p-4 md:p-6 flex flex-col md:flex-row gap-6 hover:bg-gray-50 transition-colors cursor-pointer group"
                onClick = {() => onNavigate(Screen.ORDER_DETAILS, { orderId: order.rawId })}>
  <div className="flex flex-col sm:flex-row items-start gap-4 flex-1 w-full" >
  <div className={`w-16 h-16 rounded-2xl flex items-center justify-center shrink-0 border transition-colors ${order.isUrgent ? 'bg-red-50 border-red-100 text-red-500' : 'bg-gray-100 border-gray-200 text-gray-500 group-hover:bg-white group-hover:border-primary/30 group-hover:text-primary'}`}>
  <span className="material-symbols-outlined text-2xl" >
  { order.status === 'New' ? 'notifications_active' : order.status === 'Preparing' ? 'skillet' : order.status === 'Ready' ? 'check_circle' : 'receipt_long' }
  </span>
  </div>

  < div className = "flex-1 w-full" >
  <div className="flex flex-wrap items-center gap-3 mb-1" >
  <h3 className="font-bold text-lg text-gray-900" > { order.id } </h3>
  < span className = "text-gray-400 text-sm font-medium" >— { order.user } </span>
                      { order.isUrgent && <span className="bg-red-500 text-white text-[10px] font-semibold px-2 py-0.5 rounded uppercase animate-pulse"> Gấp </span> }
    < span className = {`text-[10px] font-semibold px-2 py-0.5 rounded uppercase border ${statusMap[order.status].color}`}>
    { statusMap[order.status].label }
    </span>
    </div>
  < p className = "text-gray-500 text-sm mb-3" >
  Tổng: <span className="font-semibold text-gray-900" > { formatPrice(order.total)}</span> • {order.time}
    </p>

    < div className = "mt-3 bg-gray-50/50 rounded-lg p-3 border border-gray-100 space-y-1" >
    {
      order.items.slice(0, 2).map((item, idx) => (
        <div key= { idx } className = "flex items-center gap-2 text-sm" >
        <span className="font-semibold text-gray-900 w-5 h-5 flex items-center justify-center bg-white rounded border border-gray-200 text-[10px] shadow-sm" > { item.qty } </span>
      < span className = "text-gray-700 font-medium truncate max-w-[200px]" > { item.name } </span>
      </div>
      ))
    }
{ order.items.length > 2 && <p className="text-xs text-gray-400 italic pl-1" > + { order.items.length - 2 } món khác </p> }
</div>
  </div>
  </div>

  < div className = "flex flex-row md:flex-col lg:flex-row items-center gap-3 self-start md:self-center w-full md:w-auto mt-2 md:mt-0" >
  {
    order.status === 'New' && (
      <>
      <button disabled={ updating } className = "flex-1 md:flex-none px-4 lg:px-6 py-2.5 rounded-lg border border-gray-200 text-gray-600 font-semibold text-sm hover:bg-red-50 hover:text-red-600 hover:border-red-200 disabled:opacity-60 transition-colors"
onClick = {(e) => { e.stopPropagation(); handleStatusChange(order.rawId, 'Cancelled'); }}>
  Từ chối
    </button>
    < button disabled = { updating } className = "flex-1 md:flex-none px-4 lg:px-6 py-2.5 rounded-lg bg-primary text-white font-semibold text-sm hover:bg-orange-600 disabled:opacity-60 shadow-lg shadow-primary/20 transition-all"
onClick = {(e) => { e.stopPropagation(); handleStatusChange(order.rawId, 'Preparing'); }}>
  Chấp nhận
    </button>
    </>
                  )}
{
  order.status === 'Preparing' && (
    <button disabled={ updating } className = "w-full md:w-auto px-6 py-2.5 rounded-lg bg-green-600 text-white font-semibold text-sm hover:bg-green-700 disabled:opacity-60 shadow-lg transition-all"
  onClick = {(e) => { e.stopPropagation(); handleStatusChange(order.rawId, 'Ready'); }
}>
  Báo Sẵn sàng
    </button>
                  )}
{
  order.status === 'Ready' && (
    <span className="w-full md:w-auto px-4 py-2 rounded-lg bg-green-50 text-green-700 border border-green-200 font-semibold text-sm text-center">
      Chờ giao hàng
    </span>
  )}
</div>
  </div>
            ))
          )}
</div>
  </div>
  </div>
  );
};
