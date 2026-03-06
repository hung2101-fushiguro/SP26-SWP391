import React, { useState, useEffect, useRef } from 'react';
import { Screen } from '../types';
import { getShopName, getFullName, getAvatarUrl, getNotifications, markNotificationRead, markAllNotificationsRead, NotificationsResponse } from '../api';

interface SidebarProps {
  currentScreen: Screen;
  onNavigate: (screen: Screen, params?: any) => void;
  isOpen: boolean;
  onClose: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ currentScreen, onNavigate, isOpen, onClose }) => {
  const [avatarUrl, setAvatarUrl] = useState<string | null>(getAvatarUrl());

  useEffect(() => {
    const handler = (e: Event) => setAvatarUrl((e as CustomEvent).detail);
    window.addEventListener('ce:avatarUpdated', handler);
    return () => window.removeEventListener('ce:avatarUpdated', handler);
  }, []);

  const menuItems = [
    { id: Screen.DASHBOARD, icon: 'dashboard', label: 'Tổng quan' },
    { id: Screen.ORDERS, icon: 'shopping_bag', label: 'Đơn hàng' },
    { id: Screen.CHAT, icon: 'chat', label: 'Tin nhắn' },
    { id: Screen.MENU, icon: 'restaurant_menu', label: 'Thực đơn' },
    { id: Screen.ANALYTICS, icon: 'analytics', label: 'Phân tích' },
    { id: Screen.WALLET, icon: 'account_balance_wallet', label: 'Ví tiền' },
    { id: Screen.PROMOTIONS, icon: 'campaign', label: 'Marketing' },
    { id: Screen.REVIEWS, icon: 'star', label: 'Đánh giá' },
    { id: Screen.SETTINGS, icon: 'settings', label: 'Cài đặt' },
  ];

  const isOrdersActive = currentScreen === Screen.ORDERS || currentScreen === Screen.ORDER_DETAILS || currentScreen === Screen.REFUND;

  return (
    <>
    {/* Mobile Backdrop */ }
      {
    isOpen && (
      <div 
          className="fixed inset-0 bg-black/50 z-40 md:hidden"
    onClick = { onClose }
      > </div>
      )}

{/* Sidebar Container */ }
<aside className={
  `
        fixed top-0 left-0 z-50 h-full w-64 bg-white border-r border-gray-200 flex flex-col transition-transform duration-300 ease-in-out shrink-0
        ${isOpen ? 'translate-x-0' : '-translate-x-full'} 
        md:translate-x-0 md:static
      `}>
  <div className="p-6 flex items-center justify-between shrink-0" >
    <div className="flex items-center gap-3" >
      <div className="w-8 h-8 text-primary" >
        <svg viewBox="0 0 48 48" fill = "none" xmlns = "http://www.w3.org/2000/svg" >
          <path d="M24 4C12.95 4 4 12.95 4 24C4 35.05 12.95 44 24 44C35.05 44 44 35.05 44 24C44 12.95 35.05 4 24 4ZM24 40C15.16 40 8 32.84 8 24C8 15.16 15.16 8 24 8C32.84 8 40 15.16 40 24C40 32.84 32.84 40 24 40Z" fill = "currentColor" />
            <path d="M22 14L14 26H34L26 14H22ZM24 29C22.34 29 21 30.34 21 32C21 33.66 22.34 35 24 35C25.66 35 27 33.66 27 32C27 30.34 25.66 29 24 29Z" fill = "currentColor" />
              </svg>
              </div>
              < h1 className = "text-xl font-bold text-gray-900 tracking-tight" > ClickEat </h1>
                </div>
{/* Mobile Close Button */ }
<button onClick={ onClose } className = "md:hidden text-gray-500" >
  <span className="material-symbols-outlined" > close </span>
    </button>
    </div>

    < nav className = "flex-1 px-4 py-2 space-y-1 overflow-y-auto" >
    {
      menuItems.map((item) => {
        const isActive = currentScreen === item.id || (item.id === Screen.ORDERS && isOrdersActive);

        return (
          <button
                key= { item.id }
        onClick = {() => {
          onNavigate(item.id);
          onClose();
        }
      }
                className = {`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-semibold transition-all duration-200 ${isActive
          ? 'bg-primary/10 text-primary shadow-sm'
          : 'text-gray-500 hover:bg-gray-50 hover:text-gray-900'
          }`}
      >
      <span className={ `material-symbols-outlined ${isActive ? 'fill' : ''}` }>
        { item.icon }
        </span>
{ item.label }
{
  item.id === Screen.CHAT && (
    <span className="ml-auto bg-red-500 text-white text-[10px] font-semibold px-1.5 py-0.5 rounded-full shadow-sm" > 3 </span>
                )
}
</button>
            )
          })}
</nav>

  < div className = "p-4 border-t border-gray-100 shrink-0" >
    <div className="bg-gray-50 rounded-xl p-3 mb-4 border border-gray-100" >
      <div className="flex items-center justify-between mb-1" >
        <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider" > Trạng thái </span>
          < span className = "flex items-center gap-1 text-[10px] text-green-600 font-semibold bg-white border border-green-100 px-2 py-0.5 rounded-full shadow-sm" >
            <span className="w-1.5 h-1.5 bg-green-500 rounded-full animate-pulse" > </span>
ONLINE
  </span>
  </div>
  < p className = "text-xs text-gray-400 font-medium" > Cập nhật: Vừa xong </p>
    </div>

    < button
onClick = {() => onNavigate(Screen.LOGIN)}
className = "flex items-center gap-3 px-2 py-2 w-full hover:bg-gray-50 rounded-lg transition-colors group"
  >
  <div
  className="w-10 h-10 rounded-full border border-gray-200 group-hover:border-primary transition-colors overflow-hidden flex items-center justify-center bg-gray-100 shrink-0" >
  {
    avatarUrl
      ?<img src = { avatarUrl } alt = "avatar" className = "w-full h-full object-cover" />
    : <span className="material-symbols-outlined text-gray-400 text-xl" > storefront </span>
  }
</div>
  < div className = "text-left overflow-hidden" >
    <p className="text-sm font-semibold text-gray-900 truncate" > { getShopName() || 'ClickEat Merchant'}</p>
      < p className = "text-xs text-gray-500 truncate" > { getFullName() || 'Quản lý cửa hàng'}</p>
        </div>
        < span className = "material-symbols-outlined text-gray-400 ml-auto group-hover:text-red-500 transition-colors" > logout </span>
          </button>
          </div>
          </aside>
          </>
  );
};

interface HeaderProps {
  title: string;
  onMenuClick: () => void;
  onNavigate: (screen: Screen, params?: any) => void;
  currentScreen?: Screen;
  onBack?: () => void;
}

export const Header: React.FC<HeaderProps> = ({ title, onMenuClick, onNavigate, currentScreen, onBack }) => {
  const showBack = currentScreen === Screen.ORDER_DETAILS || currentScreen === Screen.REFUND;
  const [showNotif, setShowNotif] = useState(false);
  const [notifData, setNotifData] = useState<NotificationsResponse>({ unread: 0, items: [] });
  const [loadingNotif, setLoadingNotif] = useState(false);
  const [avatarUrl, setAvatarUrl] = useState<string | null>(getAvatarUrl());
  const panelRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = (e: Event) => setAvatarUrl((e as CustomEvent).detail);
    window.addEventListener('ce:avatarUpdated', handler);
    return () => window.removeEventListener('ce:avatarUpdated', handler);
  }, []);

  // Close panel when clicking outside
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (panelRef.current && !panelRef.current.contains(e.target as Node)) {
        setShowNotif(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const loadNotifications = async () => {
    setLoadingNotif(true);
    try {
      const data = await getNotifications();
      setNotifData(data);
    } catch {
      // ignore fetch errors for notifications
    } finally {
      setLoadingNotif(false);
    }
  };

  const handleBellClick = () => {
    const next = !showNotif;
    setShowNotif(next);
    if (next) loadNotifications();
  };

  const handleMarkRead = async (id: number) => {
    try {
      await markNotificationRead(id);
      setNotifData(prev => ({
        unread: Math.max(0, prev.unread - 1),
        items: prev.items.map(n => n.id === id ? { ...n, isRead: true } : n)
      }));
    } catch { /* ignore */ }
  };

  const handleNotifClick = async (id: number, isRead: boolean, type: string, referenceId?: number) => {
    if (!isRead) await handleMarkRead(id);
    setShowNotif(false);
    if (type.includes('ORDER') || type.includes('PAYMENT')) {
      if (referenceId) {
        onNavigate(Screen.ORDER_DETAILS, { orderId: referenceId });
      } else {
        onNavigate(Screen.ORDERS);
      }
    } else if (type.includes('CHAT') || type.includes('MESSAGE')) {
      onNavigate(Screen.CHAT, referenceId ? { chatId: referenceId } : undefined);
    } else if (type.includes('REVIEW') || type.includes('RATING')) {
      onNavigate(Screen.REVIEWS);
    } else {
      onNavigate(Screen.SETTINGS);
    }
  };

  const handleMarkAllRead = async () => {
    try {
      await markAllNotificationsRead();
      setNotifData(prev => ({
        unread: 0,
        items: prev.items.map(n => ({ ...n, isRead: true }))
      }));
    } catch { /* ignore */ }
  };

  const typeIcon = (type: string) => {
    if (type.includes('ORDER')) return 'shopping_bag';
    if (type.includes('REVIEW') || type.includes('RATING')) return 'star';
    if (type.includes('PAYMENT')) return 'payments';
    return 'notifications';
  };

  const formatTime = (dateStr: string) => {
    try {
      const d = new Date(dateStr);
      const diff = Math.floor((Date.now() - d.getTime()) / 60000);
      if (diff < 1) return 'Vừa xong';
      if (diff < 60) return `${diff} phút trước`;
      if (diff < 1440) return `${Math.floor(diff / 60)} giờ trước`;
      return `${Math.floor(diff / 1440)} ngày trước`;
    } catch { return ''; }
  };

  return (
    <header className= "bg-white border-b border-gray-200 h-16 flex items-center justify-between px-4 md:px-8 sticky top-0 z-30 shrink-0 bg-white/80 backdrop-blur-md" > <div className="flex items-center gap-4" >
      <button onClick={ onMenuClick } className = "md:hidden text-gray-500 hover:text-gray-900 p-1 rounded-lg hover:bg-gray-100" >
        <span className="material-symbols-outlined" > menu </span>
          </button>
  {
    showBack && (
      <button onClick={ onBack } className = "hidden md:flex items-center gap-1 text-gray-500 hover:text-gray-900 hover:bg-gray-100 pr-3 pl-1 py-1 rounded-lg transition-colors" >
        <span className="material-symbols-outlined" > arrow_back </span>
          < span className = "text-sm font-semibold" > Quay lại </span>
            </button>
        )}
<h2 className="text-xl font-bold text-gray-900 tracking-tight" > { title } </h2>
  </div>

  < div className = "flex items-center gap-3" >
    {/* Notification Bell */ }
    < div className = "relative" ref = { panelRef } >
      <button
            onClick={ handleBellClick }
className = "relative p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-full transition-colors"
  >
  <span className="material-symbols-outlined" > notifications </span>
{
  notifData.unread > 0 && (
    <span className="absolute top-1 right-1 min-w-[18px] h-[18px] bg-red-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center px-1 border-2 border-white" >
      { notifData.unread > 99 ? '99+' : notifData.unread }
      </span>
            )
}
{
  notifData.unread === 0 && (
    <span className="absolute top-1.5 right-1.5 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-white" > </span>
            )
}
</button>

{/* Notification Dropdown Panel */ }
{
  showNotif && (
    <div className="fixed inset-x-3 top-[4.25rem] md:absolute md:inset-auto md:right-0 md:top-full md:mt-2 w-auto md:w-96 max-h-[80vh] md:max-h-[500px] bg-white rounded-2xl shadow-2xl border border-gray-100 flex flex-col overflow-hidden z-50" >
      {/* Header */ }
      < div className = "flex items-center justify-between px-4 py-3 border-b border-gray-100 shrink-0" >
        <div className="flex items-center gap-2" >
          <h3 className="font-semibold text-gray-900" > Thông báo </h3>
  {
    notifData.unread > 0 && (
      <span className="bg-red-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full" > { notifData.unread } </span>
                  )
  }
  </div>
  {
    notifData.unread > 0 && (
      <button onClick={ handleMarkAllRead } className = "text-xs text-primary font-semibold hover:underline" >
        Đọc tất cả
          </button>
                )
  }
  </div>

  {/* List */ }
  <div className="overflow-y-auto flex-1" >
    { loadingNotif && (
      <div className="flex items-center justify-center py-8" >
        <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin" > </div>
          </div>
                )
}
{
  !loadingNotif && notifData.items.length === 0 && (
    <div className="flex flex-col items-center justify-center py-10 text-gray-400" >
      <span className="material-symbols-outlined text-4xl mb-2" > notifications_off </span>
        < p className = "text-sm font-medium" > Chưa có thông báo </p>
          </div>
                )
}
{
  !loadingNotif && notifData.items.map(n => (
    <button
                    key= { n.id }
                    onClick = {() => handleNotifClick(n.id, n.isRead, n.type, n.referenceId)}
className = {`w-full flex items-start gap-3 px-4 py-3 hover:bg-gray-50 transition-colors text-left border-b border-gray-50 last:border-0 ${!n.isRead ? 'bg-orange-50/40' : ''}`}
                  >
  <div className={ `w-9 h-9 rounded-full flex items-center justify-center shrink-0 mt-0.5 ${!n.isRead ? 'bg-primary/10 text-primary' : 'bg-gray-100 text-gray-400'}` }>
    <span className="material-symbols-outlined text-sm" > { typeIcon(n.type) } </span>
      </div>
      < div className = "flex-1 min-w-0" >
        <p className={ `text-sm leading-snug ${!n.isRead ? 'font-semibold text-gray-900' : 'text-gray-600'}` }> { n.content } </p>
          < p className = "text-[11px] text-gray-400 mt-0.5" > { formatTime(n.createdAt) } </p>
            </div>
{ !n.isRead && <div className="w-2 h-2 bg-primary rounded-full mt-2 shrink-0" > </div> }
</button>
                ))}
</div>
  </div>
          )}
</div>

  < button
onClick = {() => onNavigate(Screen.SETTINGS)}
title = "Xem hồ sơ"
className = "w-9 h-9 rounded-full border-2 border-transparent hover:border-primary hover:ring-2 hover:ring-primary/20 transition-all shrink-0 overflow-hidden flex items-center justify-center bg-gray-100"
  >
  {
    avatarUrl
      ?<img src = { avatarUrl } alt = "avatar" className = "w-full h-full object-cover" />
      : <span className="material-symbols-outlined text-gray-400 text-base" > storefront </span>
    }
</button>

  </div>
  </header>
  );
};

// ─── Mobile Bottom Navigation Bar ────────────────────────────────────────────
interface BottomNavProps {
  currentScreen: Screen;
  onNavigate: (screen: Screen) => void;
  onOpenMenu: () => void;
}

export const BottomNav: React.FC<BottomNavProps> = ({ currentScreen, onNavigate, onOpenMenu }) => {
  const isOrdersActive =
    currentScreen === Screen.ORDERS ||
    currentScreen === Screen.ORDER_DETAILS ||
    currentScreen === Screen.REFUND;

  const items: { id: Screen; icon: string; label: string; active?: boolean; badge?: number }[] = [
    { id: Screen.DASHBOARD, icon: 'dashboard', label: 'Tổng quan' },
    { id: Screen.ORDERS, icon: 'shopping_bag', label: 'Đơn hàng', active: isOrdersActive },
    { id: Screen.MENU, icon: 'restaurant_menu', label: 'Thực đơn' },
    { id: Screen.CHAT, icon: 'chat', label: 'Tin nhắn', badge: 3 },
  ];

  return (
    <nav className= "md:hidden shrink-0 bg-white border-t border-gray-200 flex items-stretch" >
    {
      items.map(item => {
        const isActive = 'active' in item && item.active !== undefined ? item.active : currentScreen === item.id;
        return (
          <button
            key= { item.id }
        onClick = {() => onNavigate(item.id)}
className = {`flex-1 flex flex-col items-center justify-center gap-0.5 py-2 transition-colors relative ${isActive ? 'text-primary' : 'text-gray-400 active:text-primary'}`}
          >
  <span className={ `material-symbols-outlined text-[22px] leading-none ${isActive ? 'fill' : ''}` }> { item.icon } </span>
    < span className = "text-[10px] font-semibold leading-none mt-0.5" > { item.label } </span>
{
  item.badge && item.badge > 0 && (
    <span className="absolute top-1.5 right-[calc(50%-14px)] min-w-[16px] h-4 bg-red-500 text-white text-[9px] font-bold rounded-full flex items-center justify-center px-1 border-2 border-white" >
      { item.badge }
      </span>
            )
}
</button>
        );
      })}
{/* More button → opens sidebar drawer */ }
<button
        onClick={ onOpenMenu }
className = "flex-1 flex flex-col items-center justify-center gap-0.5 py-2 text-gray-400 active:text-primary transition-colors"
  >
  <span className="material-symbols-outlined text-[22px] leading-none" > apps </span>
    < span className = "text-[10px] font-semibold leading-none mt-0.5" > Thêm </span>
      </button>
      </nav>
  );
};