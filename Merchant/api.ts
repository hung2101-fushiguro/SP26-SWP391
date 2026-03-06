/** Central API client for ClickEat Merchant frontend.
 *  All requests use the context-relative base /merchant/api so that
 *  they work whether served by Tomcat (/merchant) or dev-proxy.
 */

const BASE = '/merchant/api';

// ---------------------------------------------------------------------------
// Token helpers
// ---------------------------------------------------------------------------
export const getToken = (): string | null => localStorage.getItem('ce_token');
export const getMerchantId = (): string | null => localStorage.getItem('ce_merchantId');
export const getShopName = (): string | null => localStorage.getItem('ce_shopName');
export const getFullName = (): string | null => localStorage.getItem('ce_name');
export const getAvatarUrl = (): string | null => localStorage.getItem('ce_avatar');
export const saveAvatarUrl = (url: string | null) => {
    if (url) localStorage.setItem('ce_avatar', url);
    else localStorage.removeItem('ce_avatar');
};

export function saveSession(token: string, merchantId: string | number, name: string, shopName: string) {
    localStorage.setItem('ce_token', token);
    localStorage.setItem('ce_merchantId', String(merchantId));
    localStorage.setItem('ce_name', name);
    localStorage.setItem('ce_shopName', shopName);
}

export function clearSession() {
    localStorage.removeItem('ce_token');
    localStorage.removeItem('ce_merchantId');
    localStorage.removeItem('ce_name');
    localStorage.removeItem('ce_shopName');
    localStorage.removeItem('ce_avatar');
}

export function isLoggedIn(): boolean {
    return !!getToken();
}

// ---------------------------------------------------------------------------
// Fetch helpers
// ---------------------------------------------------------------------------
function authHeaders(): Record<string, string> {
    const tok = getToken();
    return tok
        ? { 'Content-Type': 'application/json', Authorization: `Bearer ${tok}` }
        : { 'Content-Type': 'application/json' };
}

/** Unwrap {success, data} envelope returned by all backend endpoints. */
function unwrap<T>(json: any): T {
    return (json !== null && typeof json === 'object' && 'data' in json) ? json.data : json;
}

/** Handle 401: clear session and signal app to go to login */
function handle401(): never {
    clearSession();
    window.dispatchEvent(new CustomEvent('ce:unauthorized'));
    throw new Error('Unauthorized');
}

async function get<T>(url: string): Promise<T> {
    const res = await fetch(BASE + url, { headers: authHeaders() });
    if (res.status === 401) handle401();
    if (!res.ok) {
        const j = await res.json().catch(() => null);
        throw new Error(j?.message || `GET ${url}: ${res.status}`);
    }
    return unwrap<T>(await res.json());
}

async function post<T>(url: string, body: unknown): Promise<T> {
    const res = await fetch(BASE + url, {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify(body),
    });
    if (res.status === 401) handle401();
    if (!res.ok) {
        const j = await res.json().catch(() => null);
        throw new Error(j?.message || `POST ${url}: ${res.status}`);
    }
    return unwrap<T>(await res.json());
}

async function put<T>(url: string, body: unknown): Promise<T> {
    const res = await fetch(BASE + url, {
        method: 'PUT',
        headers: authHeaders(),
        body: JSON.stringify(body),
    });
    if (res.status === 401) handle401();
    if (!res.ok) {
        const j = await res.json().catch(() => null);
        throw new Error(j?.message || `PUT ${url}: ${res.status}`);
    }
    return unwrap<T>(await res.json());
}

async function patch<T>(url: string, body: unknown): Promise<T> {
    const res = await fetch(BASE + url, {
        method: 'PATCH',
        headers: authHeaders(),
        body: JSON.stringify(body),
    });
    if (res.status === 401) handle401();
    if (!res.ok) {
        const j = await res.json().catch(() => null);
        throw new Error(j?.message || `PATCH ${url}: ${res.status}`);
    }
    return unwrap<T>(await res.json());
}

async function del(url: string): Promise<void> {
    const res = await fetch(BASE + url, { method: 'DELETE', headers: authHeaders() });
    if (res.status === 401) handle401();
    if (!res.ok) throw new Error(`DELETE ${url}: ${res.status}`);
}

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------
export interface LoginResponse {
    token: string;
    merchantId: number;
    name: string;
    email: string;
    shopName: string;
    shopStatus: string;
}

export async function login(email: string, password: string): Promise<LoginResponse> {
    const res = await fetch(BASE + '/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
    });
    if (!res.ok) {
        const j = await res.json().catch(() => null);
        throw new Error(j?.message || 'Invalid email or password');
    }
    return unwrap<LoginResponse>(await res.json());
}

export async function googleLogin(credential: string): Promise<LoginResponse> {
    const res = await fetch(BASE + '/auth/google', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ credential }),
    });
    const j = await res.json().catch(() => null);
    if (res.status === 404 && j?.notRegistered) {
        const err: any = new Error('NOT_REGISTERED');
        err.notRegistered = true;
        err.email = j.email ?? '';
        err.name = j.name ?? '';
        throw err;
    }
    if (!res.ok) {
        throw new Error(j?.message || 'Tài khoản không tồn tại hoặc chưa được phê duyệt');
    }
    return unwrap<LoginResponse>(j);
}

export async function forgotPassword(phone: string): Promise<{ message: string }> {
    const res = await fetch(BASE + '/auth/forgot-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone }),
    });
    const j = await res.json().catch(() => null);
    if (!res.ok) throw new Error(j?.message || 'Lỗi gửi OTP');
    return unwrap<{ message: string }>(j);
}

export async function resetPassword(phone: string, otp: string, newPassword: string): Promise<{ message: string }> {
    const res = await fetch(BASE + '/auth/reset-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone, otp, newPassword }),
    });
    const j = await res.json().catch(() => null);
    if (!res.ok) throw new Error(j?.message || 'OTP không hợp lệ');
    return unwrap<{ message: string }>(j);
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------
export interface DashboardStats {
    todayRevenue: number;
    todayOrders: number;
    pendingOrders: number;
    avgRating: number;
    weeklyRevenue: number[];
    weeklyOrders: number[];
    topItems: { name: string; orders: number }[];
    recentOrders: { id: number; orderCode: string; customerName: string; total: number; status: string; createdAt: string }[];
}

export function getDashboard(): Promise<DashboardStats> {
    return get<DashboardStats>('/dashboard');
}

// ---------------------------------------------------------------------------
// Orders
// ---------------------------------------------------------------------------
export interface OrderItem {
    id: number;
    foodItemId: number;
    itemNameSnapshot: string;
    quantity: number;
    unitPriceSnapshot: number;  // backend field name
}

export interface Order {
    id: number;
    orderCode: string;
    receiverName: string;        // backend: receiver_name
    receiverPhone: string;       // backend: receiver_phone
    deliveryAddressLine: string; // backend: delivery_address_line
    orderStatus: string;
    totalAmount: number;
    createdAt: string;
    items: OrderItem[];
    isUrgent?: boolean;
}

export interface OrdersResponse {
    items: Order[];
    total: number;
    page: number;
    pageSize: number;
}

export function getOrders(status?: string, page = 1, pageSize = 20): Promise<OrdersResponse> {
    const q = new URLSearchParams();
    if (status) q.set('status', status);
    q.set('page', String(page));
    q.set('pageSize', String(pageSize));
    return get<OrdersResponse>(`/orders?${q}`);
}

export function getOrderById(id: number): Promise<Order> {
    return get<Order>(`/orders/${id}`);
}

export function updateOrderStatus(id: number, status: string): Promise<unknown> {
    return patch<unknown>(`/orders/${id}/status`, { status });
}

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------
export interface Category {
    id: number;
    name: string;
    sortOrder: number;
    active: boolean;
}

export function getCategories(): Promise<Category[]> {
    return get<Category[]>('/categories');
}

export function createCategory(name: string): Promise<Category> {
    return post<Category>('/categories', { name });
}

export function updateCategory(id: number, name: string): Promise<Category> {
    return put<Category>(`/categories/${id}`, { name });
}

export function deleteCategory(id: number): Promise<void> {
    return del(`/categories/${id}`);
}

// ---------------------------------------------------------------------------
// Menu Items
// ---------------------------------------------------------------------------
export interface MenuItemAPI {
    id: number;
    merchantUserId: number;
    categoryId: number;
    categoryName?: string;
    name: string;
    description?: string;
    price: number;
    imageUrl?: string;
    available: boolean;
}

export function getMenuItems(): Promise<MenuItemAPI[]> {
    return get<MenuItemAPI[]>('/menu-items');
}

export function createMenuItem(data: {
    categoryId: number;
    name: string;
    description?: string;
    price: number;
    imageUrl?: string;
}): Promise<MenuItemAPI> {
    return post<MenuItemAPI>('/menu-items', data);
}

export function updateMenuItem(id: number, data: {
    categoryId: number;
    name: string;
    description?: string;
    price: number;
    imageUrl?: string;
    isAvailable?: boolean;
}): Promise<MenuItemAPI> {
    return put<MenuItemAPI>(`/menu-items/${id}`, data);
}

export function toggleMenuItemAvailability(id: number, available: boolean): Promise<unknown> {
    return patch<unknown>(`/menu-items/${id}/availability`, { available });
}

export function deleteMenuItem(id: number): Promise<void> {
    return del(`/menu-items/${id}`);
}

// ---------------------------------------------------------------------------
// Reviews
// ---------------------------------------------------------------------------
export interface Review {
    id: number;
    orderId: number;
    raterId: number;
    raterName: string;
    stars: number;
    comment: string;
    createdAt: string;
}

export interface ReviewsResponse {
    items: Review[];
    total: number;
    avgStars: number;      // backend key: avgStars (ReviewService)
    page: number;
    pageSize: number;
}

export function getReviews(page = 1, pageSize = 20): Promise<ReviewsResponse> {
    return get<ReviewsResponse>(`/reviews?page=${page}&pageSize=${pageSize}`);
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------
export interface BusinessHourDay {
    day: 'MON' | 'TUE' | 'WED' | 'THU' | 'FRI' | 'SAT' | 'SUN';
    open: boolean;
    from: string; // "HH:mm"
    to: string;   // "HH:mm"
}

export interface MerchantProfile {
    userId: number;
    email: string;
    fullName: string;
    shopName: string;
    shopPhone: string;
    shopAddressLine: string;
    shopStatus: string;
    businessHours?: string | null; // JSON string of BusinessHourDay[]
    avatarUrl?: string | null;     // base64 data URL or external URL
}

export function getSettings(): Promise<MerchantProfile> {
    return get<MerchantProfile>('/settings/profile');
}

export function updateSettings(data: {
    shopName: string;
    shopPhone: string;
    shopAddressLine: string;
}): Promise<MerchantProfile> {
    return put<MerchantProfile>('/settings/profile', data);
}

export function updateBusinessHours(hours: BusinessHourDay[]): Promise<MerchantProfile> {
    return put<MerchantProfile>('/settings/hours', { businessHours: JSON.stringify(hours) });
}

export function updateAvatarUrl(avatarUrl: string): Promise<MerchantProfile> {
    return put<MerchantProfile>('/settings/avatar', { avatarUrl });
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------
export interface NotificationItem {
    id: number;
    type: string;
    content: string;
    referenceId?: number;  // order_id | chat_id | rating_id
    isRead: boolean;
    createdAt: string;
}

export interface NotificationsResponse {
    unread: number;
    items: NotificationItem[];
}

export function getNotifications(): Promise<NotificationsResponse> {
    return get<NotificationsResponse>('/notifications');
}

export function markNotificationRead(id: number): Promise<unknown> {
    return patch<unknown>(`/notifications/${id}`, {});
}

export function markAllNotificationsRead(): Promise<unknown> {
    return patch<unknown>('/notifications/read-all', {});
}

// ---------------------------------------------------------------------------
// Vouchers
// ---------------------------------------------------------------------------
export interface VoucherAPI {
    id: number;
    code: string;
    title: string;
    description?: string;
    discountType: 'PERCENT' | 'FIXED';
    discountValue: number;
    maxDiscountAmount?: number;
    minOrderAmount?: number;
    startAt: string;
    endAt: string;
    maxUsesTotal?: number;
    maxUsesPerUser?: number;
    isPublished: boolean;
    status: 'ACTIVE' | 'INACTIVE';
    usedCount: number;
    createdAt: string;
}

export function getVouchers(): Promise<VoucherAPI[]> {
    return get<VoucherAPI[]>('/vouchers');
}

export function createVoucher(data: {
    code: string;
    title: string;
    description?: string;
    discountType: string;
    discountValue: number;
    maxDiscountAmount?: number;
    minOrderAmount?: number;
    startAt?: string;
    endAt?: string;
    maxUsesTotal?: number;
}): Promise<{ id: number }> {
    return post<{ id: number }>('/vouchers', data);
}

export function toggleVoucherStatus(id: number): Promise<unknown> {
    return patch<unknown>(`/vouchers/${id}/toggle-status`, {});
}

export function toggleVoucherPublished(id: number): Promise<unknown> {
    return patch<unknown>(`/vouchers/${id}/toggle-published`, {});
}

export function deleteVoucher(id: number): Promise<void> {
    return del(`/vouchers/${id}`);
}

// ---------------------------------------------------------------------------
// Analytics
// ---------------------------------------------------------------------------
export interface AnalyticsSummary {
    totalOrders: number;
    totalRevenue: number;
    avgOrderValue: number;
    cancelledOrders: number;
}

export interface DailyRevenue {
    day: string;
    orders: number;
    revenue: number;
}

export interface AnalyticsResponse {
    period: number;
    summary: AnalyticsSummary;
    dailyRevenue: DailyRevenue[];
    statusBreakdown: Record<string, number>;
    topItems: { name: string; qty: number; revenue: number }[];
}

export function getAnalytics(period: 7 | 30 | 365 = 7): Promise<AnalyticsResponse> {
    return get<AnalyticsResponse>(`/analytics?period=${period}`);
}

// ---------------------------------------------------------------------------
// Wallet
// ---------------------------------------------------------------------------
export interface WithdrawalRequest {
    id: number;
    amount: number;
    bankName: string;
    bankAccount: string;
    accountHolder: string;
    status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'COMPLETED';
    note?: string | null;
    createdAt: string;
    processedAt?: string | null;
}

export interface WalletStats {
    availableBalance: number;
    totalRevenue: number;
    monthRevenue: number;
    pendingRevenue: number;
    deliveredCount: number;
    recentTransactions: { orderCode: string; amount: number; status: string; date: string }[];
    withdrawals: WithdrawalRequest[];
}

export function getWallet(): Promise<WalletStats> {
    return get<WalletStats>('/wallet');
}

export function getWithdrawals(): Promise<WithdrawalRequest[]> {
    return get<WithdrawalRequest[]>('/wallet/withdrawals');
}

export function requestWithdrawal(data: {
    amount: number;
    bankName: string;
    bankAccount: string;
    accountHolder: string;
}): Promise<{ id: number; status: string; message: string }> {
    return post('/wallet/withdraw', data);
}
