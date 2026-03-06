import React, { useState, useEffect } from 'react';
import { Screen } from './types';
import { Sidebar, Header, BottomNav } from './components/Navigation';
import { Dashboard } from './screens/Dashboard';
import { OrderManagement } from './screens/OrderManagement';
import { Catalog } from './screens/Catalog';
import { MarketingAndFinance } from './screens/MarketingAndFinance';
import { Onboarding } from './screens/Onboarding';
import { Analytics } from './screens/Analytics';
import { Reviews } from './screens/Reviews';
import { Settings } from './screens/Settings';
import { Refund } from './screens/Refund';
import { Chat } from './screens/Chat';
import { isLoggedIn, clearSession } from './api';

const SCREEN_KEY = 'ce_screen';
const AUTH_SCREENS = new Set<Screen>([
  Screen.LOGIN, Screen.FORGOT_PASSWORD, Screen.RESET_PASSWORD,
  Screen.REGISTER_STEP_1, Screen.REGISTER_STEP_2,
  Screen.REGISTER_STEP_3, Screen.REGISTER_SUCCESS,
]);

function getInitialScreen(): Screen {
  if (!isLoggedIn()) return Screen.LOGIN;
  const saved = localStorage.getItem(SCREEN_KEY) as Screen | null;
  // Restore saved screen, but never restore auth screens or ORDER_DETAILS (needs params)
  if (saved && !AUTH_SCREENS.has(saved) && saved !== Screen.ORDER_DETAILS) {
    return saved;
  }
  return Screen.DASHBOARD;
}

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>(getInitialScreen);

  // Auto-logout when any API call returns 401
  useEffect(() => {
    const onUnauthorized = () => {
      localStorage.removeItem(SCREEN_KEY);
      setCurrentScreen(Screen.LOGIN);
    };
    window.addEventListener('ce:unauthorized', onUnauthorized);
    return () => window.removeEventListener('ce:unauthorized', onUnauthorized);
  }, []);
  const [screenParams, setScreenParams] = useState<any>(null);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  // Advanced Navigation Handler
  const handleNavigate = (screen: Screen, params: any = null) => {
    if (screen === Screen.LOGIN) {
      clearSession();
      localStorage.removeItem(SCREEN_KEY);
    } else if (!AUTH_SCREENS.has(screen)) {
      localStorage.setItem(SCREEN_KEY, screen);
    }
    setCurrentScreen(screen);
    setScreenParams(params);
  };

  // Auth Screens wrap themselves
  if (
    currentScreen === Screen.LOGIN ||
    currentScreen === Screen.FORGOT_PASSWORD ||
    currentScreen === Screen.RESET_PASSWORD ||
    currentScreen === Screen.REGISTER_SUCCESS ||
    currentScreen.startsWith('REGISTER')
  ) {
    return <Onboarding screen={ currentScreen } onNavigate = { handleNavigate } />;
  }

  // Determine Title (Vietnamese)
  const getTitle = () => {
    switch (currentScreen) {
      case Screen.DASHBOARD: return 'Tổng quan';
      case Screen.ORDERS: return 'Quản lý Đơn hàng';
      case Screen.ORDER_DETAILS: return 'Chi tiết Đơn hàng';
      case Screen.MENU: return 'Quản lý Thực đơn';
      case Screen.WALLET: return 'Ví tiền';
      case Screen.PROMOTIONS: return 'Khuyến mãi';
      case Screen.ANALYTICS: return 'Báo cáo & Phân tích';
      case Screen.REVIEWS: return 'Đánh giá khách hàng';
      case Screen.SETTINGS: return 'Cài đặt cửa hàng';
      case Screen.REFUND: return 'Hoàn tiền';
      case Screen.CHAT: return 'Tin nhắn';
      default: return 'ClickEat';
    }
  };

  return (
    <div className= "flex bg-[#f8f7f5] h-full w-full text-slate-900" >
    <Sidebar 
        currentScreen={ currentScreen }
  onNavigate = { handleNavigate }
  isOpen = { isMobileMenuOpen }
  onClose = {() => setIsMobileMenuOpen(false)
}
      />
  < div className = "flex-1 flex flex-col h-full min-w-0 overflow-hidden md:ml-0 relative" >
    <Header 
          title={ getTitle() }
onMenuClick = {() => setIsMobileMenuOpen(true)}
onNavigate = { handleNavigate }
currentScreen = { currentScreen }
onBack = {() => handleNavigate(Screen.ORDERS)}
        />
  < main className = {`flex-1 min-h-0 scroll-smooth ${currentScreen === Screen.CHAT ? 'overflow-hidden flex flex-col' : 'overflow-y-auto overflow-x-hidden'}`} >
    { currentScreen === Screen.DASHBOARD && <Dashboard />}
{ currentScreen === Screen.ORDERS && <OrderManagement view="LIST" onNavigate = { handleNavigate } />}
{ currentScreen === Screen.ORDER_DETAILS && <OrderManagement view="DETAIL" onNavigate = { handleNavigate } params = { screenParams } />}
{ currentScreen === Screen.MENU && <Catalog /> }
{
  (currentScreen === Screen.WALLET || currentScreen === Screen.PROMOTIONS) && (
    <MarketingAndFinance screen={ currentScreen } />
          )
}
{ currentScreen === Screen.ANALYTICS && <Analytics /> }
{ currentScreen === Screen.REVIEWS && <Reviews /> }
{ currentScreen === Screen.SETTINGS && <Settings /> }
{ currentScreen === Screen.REFUND && <Refund onNavigate={ handleNavigate } /> }
{ currentScreen === Screen.CHAT && <Chat initialChatId={ screenParams?.chatId } /> }
</main>
  < BottomNav
currentScreen = { currentScreen }
onNavigate = { handleNavigate }
onOpenMenu = {() => setIsMobileMenuOpen(true)}
  />
  </div>
  </div>
  );
}