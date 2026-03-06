import React, { useState } from 'react';
import { Screen } from '../types';

interface RefundProps {
  onNavigate: (screen: Screen) => void;
}

export const Refund: React.FC<RefundProps> = ({ onNavigate }) => {
  const [selectedItems, setSelectedItems] = useState<string[]>([]);
  const [reason, setReason] = useState('');

  const orderItems = [
    { id: '1', name: 'Burger Gà Cay', price: 45000, qty: 2 },
    { id: '2', name: 'Khoai tây lớn', price: 25000, qty: 1 },
    { id: '3', name: 'Coca Cola', price: 15000, qty: 1 },
  ];

  const handleToggle = (id: string) => {
    if (selectedItems.includes(id)) {
      setSelectedItems(selectedItems.filter(item => item !== id));
    } else {
      setSelectedItems([...selectedItems, id]);
    }
  };

  const calculateRefund = () => {
    return selectedItems.reduce((acc, id) => {
      const item = orderItems.find(i => i.id === id);
      return acc + (item ? item.price * item.qty : 0);
    }, 0);
  };

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price);
  };

  return (
    <div className="p-4 md:p-8 max-w-2xl mx-auto flex items-center justify-center min-h-[80vh]">
      <div className="bg-white w-full rounded-2xl shadow-xl border border-gray-200 overflow-hidden">
        <div className="px-6 md:px-8 py-6 border-b border-gray-100 flex justify-between items-center bg-gray-50">
          <h2 className="text-xl font-bold text-gray-900">Xử lý Hoàn tiền</h2>
          <button onClick={() => onNavigate(Screen.ORDER_DETAILS)} className="text-gray-400 hover:text-gray-600">
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>
        
        <div className="p-6 md:p-8 space-y-6">
          <div className="bg-yellow-50 border border-yellow-100 rounded-lg p-4 flex gap-3">
             <span className="material-symbols-outlined text-yellow-600">info</span>
             <p className="text-sm text-yellow-800">Hoàn tiền được xử lý ngay lập tức và không thể hoàn tác sau khi xác nhận.</p>
          </div>

          <div>
             <h3 className="font-semibold text-sm text-gray-800 mb-3">Chọn món cần hoàn tiền</h3>
             <div className="space-y-2">
                {orderItems.map((item) => (
                   <div key={item.id} 
                        onClick={() => handleToggle(item.id)}
                        className={`flex justify-between items-center p-4 rounded-xl border cursor-pointer transition-all ${selectedItems.includes(item.id) ? 'border-primary bg-orange-50/50' : 'border-gray-200 hover:border-gray-300'}`}>
                      <div className="flex items-center gap-3">
                         <div className={`w-5 h-5 rounded border flex items-center justify-center ${selectedItems.includes(item.id) ? 'bg-primary border-primary text-white' : 'border-gray-300 bg-white'}`}>
                            {selectedItems.includes(item.id) && <span className="material-symbols-outlined text-sm">check</span>}
                         </div>
                         <div>
                            <p className="font-semibold text-gray-900 text-sm">{item.qty}x {item.name}</p>
                         </div>
                      </div>
                      <span className="font-semibold text-gray-900">{formatPrice(item.price * item.qty)}</span>
                   </div>
                ))}
             </div>
          </div>

          <div>
             <label className="block text-sm font-semibold text-gray-800 mb-2">Lý do hoàn tiền</label>
             <div className="relative">
               <select 
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 outline-none focus:bg-white focus:border-primary focus:ring-4 focus:ring-primary/10 transition-all font-medium appearance-none text-gray-900"
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
               >
                  <option value="">Chọn lý do...</option>
                  <option value="missing">Thiếu món</option>
                  <option value="quality">Chất lượng đồ ăn kém</option>
                  <option value="wrong">Giao sai món</option>
                  <option value="customer">Khách hàng yêu cầu</option>
               </select>
               <span className="material-symbols-outlined absolute right-3 top-3.5 text-gray-500 pointer-events-none">expand_more</span>
             </div>
          </div>
        </div>

        <div className="px-6 md:px-8 py-6 bg-gray-50 border-t border-gray-100 flex justify-between items-center">
           <div>
              <p className="text-xs text-gray-500 uppercase font-semibold tracking-wider">Tổng hoàn lại</p>
              <p className="text-2xl font-bold text-primary">{formatPrice(calculateRefund())}</p>
           </div>
           <div className="flex gap-3">
              <button onClick={() => onNavigate(Screen.ORDER_DETAILS)} className="px-6 py-2.5 rounded-lg border border-gray-300 text-gray-600 font-semibold text-sm hover:bg-white transition-colors">Hủy</button>
              <button 
                onClick={() => { alert('Đã hoàn tiền thành công!'); onNavigate(Screen.ORDER_DETAILS); }}
                disabled={selectedItems.length === 0 || !reason}
                className="px-6 py-2.5 rounded-lg bg-red-500 text-white font-semibold text-sm hover:bg-red-600 shadow-md disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                 Xác nhận
              </button>
           </div>
        </div>
      </div>
    </div>
  );
};