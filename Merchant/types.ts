
export enum Screen {
  LOGIN = 'LOGIN',
  FORGOT_PASSWORD = 'FORGOT_PASSWORD',
  RESET_PASSWORD = 'RESET_PASSWORD',
  REGISTER_STEP_1 = 'REGISTER_STEP_1',
  REGISTER_STEP_2 = 'REGISTER_STEP_2',
  REGISTER_STEP_3 = 'REGISTER_STEP_3',
  REGISTER_SUCCESS = 'REGISTER_SUCCESS',
  DASHBOARD = 'DASHBOARD',
  ORDERS = 'ORDERS',
  ORDER_DETAILS = 'ORDER_DETAILS',
  MENU = 'MENU',
  ANALYTICS = 'ANALYTICS',
  WALLET = 'WALLET',
  PROMOTIONS = 'PROMOTIONS',
  REVIEWS = 'REVIEWS',
  SETTINGS = 'SETTINGS',
  REFUND = 'REFUND',
  CHAT = 'CHAT'
}

export interface MenuItem {
  id: string;
  name: string;
  price: number;
  category: string;
  image: string;
  available: boolean;
  labels?: string[];
}

export interface Order {
  id: string;
  customerName: string;
  total: number;
  status: 'New' | 'Preparing' | 'Ready' | 'Delivered' | 'Cancelled';
  time: string;
  items: string[];
  isUrgent?: boolean;
}
