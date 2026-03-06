import React, { useState, useEffect } from 'react';
import { Screen } from '../types';
import {
  getWallet, WalletStats, requestWithdrawal, WithdrawalRequest,
  getVouchers, createVoucher, toggleVoucherStatus, toggleVoucherPublished, deleteVoucher, VoucherAPI,
} from '../api';

const fmt = (n: number) => new Intl.NumberFormat('vi-VN').format(Math.round(n)) + 'đ';
const fmtDate = (s: string) => { try { return new Date(s).toLocaleDateString('vi-VN'); } catch { return s; } };
const fmtDateTime = (s?: string | null) => {
  if (!s) return '–';
  try {
    return new Date(s).toLocaleString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
  } catch { return s; }
};

const BANKS = [
  'Vietcombank', 'VietinBank', 'BIDV', 'Agribank', 'Techcombank',
  'MB Bank', 'ACB', 'VPBank', 'TPBank', 'Sacombank', 'HDBank', 'OCB',
];

const withdrawalStatusCfg = (s: string) => {
  switch (s) {
    case 'PENDING':   return { label: 'Đang chờ',  cls: 'bg-yellow-100 text-yellow-700', icon: 'hourglass_empty' };
    case 'APPROVED':  return { label: 'Đã duyệt',  cls: 'bg-blue-100 text-blue-700',    icon: 'thumb_up' };
    case 'COMPLETED': return { label: 'Hoàn thành', cls: 'bg-green-100 text-green-700',  icon: 'check_circle' };
    case 'REJECTED':  return { label: 'Từ chối',   cls: 'bg-red-100 text-red-600',      icon: 'cancel' };
    default:          return { label: s,             cls: 'bg-gray-100 text-gray-600',    icon: 'info' };
  }
};

const EMPTY_WITHDRAW = { amount: '', bankName: '', bankAccount: '', accountHolder: '' };

export const MarketingAndFinance: React.FC<{ screen: Screen }> = ({ screen }) => {
  // ---------------------------------------------------------------- Wallet
  const [wallet, setWallet] = useState<WalletStats | null>(null);
  const [walletLoading, setWalletLoading] = useState(false);

  // ---------------------------------------------------------------- Withdrawal modal
  const [showWithdraw, setShowWithdraw] = useState(false);
  const [wForm, setWForm] = useState(EMPTY_WITHDRAW);
  const [wSaving, setWSaving] = useState(false);
  const [wError, setWError] = useState('');
  const [withdrawals, setWithdrawals] = useState<WithdrawalRequest[]>([]);

  // ---------------------------------------------------------------- Vouchers
  const [vouchers, setVouchers] = useState<VoucherAPI[]>([]);
  const [voucherLoading, setVoucherLoading] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [newV, setNewV] = useState({ title: '', code: '', discountType: 'PERCENT', discountValue: '', minOrderAmount: '', startAt: '', endAt: '', maxUsesTotal: '' });
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState('');

  const showToast = (msg: string) => { setToast(msg); setTimeout(() => setToast(''), 3000); };

  useEffect(() => {
    if (screen === Screen.WALLET) {
      setWalletLoading(true);
      getWallet()
        .then(w => { setWallet(w); setWithdrawals(w.withdrawals ?? []); })
        .catch(() => setWallet(null))
        .finally(() => setWalletLoading(false));
    } else {
      setVoucherLoading(true);
      getVouchers().then(setVouchers).catch(() => setVouchers([])).finally(() => setVoucherLoading(false));
    }
  }, [screen]);

  const handleWithdraw = async () => {
    setWError('');
    const amount = parseFloat(wForm.amount.replace(/\D/g, ''));
    if (!amount || amount < 100000) { setWError('Số tiền rút tối thiểu là 100,000đ'); return; }
    if (!wForm.bankName) { setWError('Vui lòng chọn ngân hàng'); return; }
    if (!wForm.bankAccount.trim()) { setWError('Vui lòng nhập số tài khoản'); return; }
    if (!wForm.accountHolder.trim()) { setWError('Vui lòng nhập tên chủ tài khoản'); return; }
    if (wallet && amount > wallet.availableBalance) { setWError('Số tiền vượt quá số dư khả dụng'); return; }

    setWSaving(true);
    try {
      await requestWithdrawal({
        amount,
        bankName: wForm.bankName,
        bankAccount: wForm.bankAccount.trim(),
        accountHolder: wForm.accountHolder.trim().toUpperCase(),
      });
      setShowWithdraw(false);
      setWForm(EMPTY_WITHDRAW);
      showToast('✅ Yêu cầu rút tiền đã được ghi nhận!');
      // Refresh wallet
      const updated = await getWallet();
      setWallet(updated);
      setWithdrawals(updated.withdrawals ?? []);
    } catch (e: any) {
      setWError(e.message || 'Có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      setWSaving(false);
    }
  };

  const openWithdraw = () => { setWForm(EMPTY_WITHDRAW); setWError(''); setShowWithdraw(true); };

  const handleCreate = async () => {
    if (!newV.title.trim() || !newV.code.trim()) { showToast('Vui lòng điền Tên và Mã code'); return; }
    setSaving(true);
    try {
      await createVoucher({
        code: newV.code,
        title: newV.title,
        discountType: newV.discountType,
        discountValue: parseFloat(newV.discountValue) || 0,
        minOrderAmount: newV.minOrderAmount ? parseFloat(newV.minOrderAmount) : undefined,
        startAt: newV.startAt ? newV.startAt + 'T00:00:00' : undefined,
        endAt: newV.endAt ? newV.endAt + 'T23:59:59' : undefined,
        maxUsesTotal: newV.maxUsesTotal ? parseInt(newV.maxUsesTotal) : undefined,
      });
      setIsModalOpen(false);
      setNewV({ title: '', code: '', discountType: 'PERCENT', discountValue: '', minOrderAmount: '', startAt: '', endAt: '', maxUsesTotal: '' });
      const updated = await getVouchers();
      setVouchers(updated);
      showToast('Tạo khuyến mãi thành công!');
    } catch (e: any) {
      showToast(e.message || 'Có lỗi xảy ra');
    } finally { setSaving(false); }
  };

  const handleToggle = async (id: number) => {
    try {
      await toggleVoucherStatus(id);
      setVouchers(vs => vs.map(v => v.id === id ? { ...v, status: v.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE' } : v));
    } catch { showToast('Không thể thay đổi trạng thái'); }
  };

  const handleDelete = async (id: number) => {
    if (!window.confirm('Xoá khuyến mãi này?')) return;
    try {
      await deleteVoucher(id);
      setVouchers(vs => vs.filter(v => v.id !== id));
      showToast('Đã xoá khuyến mãi');
    } catch { showToast('Không thể xoá'); }
  };

  // =================== WALLET ===================
  if (screen === Screen.WALLET) {
    return (
      <div className="p-4 md:p-8 max-w-7xl mx-auto space-y-8 relative">
        {/* Toast */}
        {toast && (
          <div className="fixed top-6 right-6 z-[100] bg-gray-900 text-white px-5 py-3 rounded-xl shadow-2xl text-sm font-semibold">{toast}</div>
        )}

        <div className="flex flex-col gap-1">
          <h1 className="text-3xl md:text-4xl font-bold text-gray-900 tracking-tight">Ví tiền</h1>
          <p className="text-gray-500">Quản lý thu nhập và rút tiền</p>
        </div>

        {walletLoading && <div className="flex items-center justify-center h-64"><div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin"></div></div>}

        {!walletLoading && (
          <>
            {/* Balance card */}
            <div className="relative overflow-hidden rounded-2xl bg-primary text-white p-6 md:p-10 shadow-xl group">
              <span className="material-symbols-outlined absolute -right-10 -top-10 text-[180px] md:text-[240px] opacity-10 group-hover:scale-110 transition-transform duration-700">account_balance_wallet</span>
              <div className="relative z-10">
                <p className="text-white/80 font-medium text-lg">Số dư khả dụng</p>
                <h2 className="text-4xl md:text-6xl font-bold mt-2 mb-2">{wallet ? fmt(wallet.availableBalance) : '–'}</h2>
                <p className="text-white/60 text-sm mb-6">Sau phí nền tảng 10% · {wallet?.deliveredCount ?? 0} đơn hoàn thành</p>
                <div className="flex flex-wrap gap-3">
                  <button
                    onClick={openWithdraw}
                    disabled={!wallet || wallet.availableBalance <= 0}
                    className="bg-white text-primary px-6 md:px-8 py-3 rounded-xl font-bold shadow-lg hover:bg-gray-50 transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <span className="material-symbols-outlined text-xl">payments</span> Rút tiền
                  </button>
                </div>
              </div>
            </div>

            {/* Stats grid */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {[
                { label: 'Tổng thu nhập', value: wallet?.totalRevenue, sub: null },
                { label: 'Tháng này', value: wallet?.monthRevenue, sub: null },
                { label: 'Đang xử lý', value: wallet?.pendingRevenue, sub: 'Chờ giao' },
              ].map(s => (
                <div key={s.label} className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
                  <p className="text-gray-400 text-xs font-semibold uppercase tracking-wider mb-2">{s.label}</p>
                  <div className="flex items-baseline gap-2">
                    <h3 className="text-2xl md:text-3xl font-semibold">{s.value != null ? fmt(s.value) : '–'}</h3>
                    {s.sub && <span className="text-gray-500 text-xs font-semibold bg-gray-100 px-2 py-0.5 rounded">{s.sub}</span>}
                  </div>
                </div>
              ))}
            </div>

            {/* Withdrawal history */}
            <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
              <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
                <h3 className="font-semibold text-lg">Lịch sử rút tiền</h3>
                <button onClick={openWithdraw} className="text-primary text-sm font-semibold hover:underline flex items-center gap-1">
                  <span className="material-symbols-outlined text-base">add</span>Yêu cầu mới
                </button>
              </div>
              {withdrawals.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12 text-gray-400">
                  <span className="material-symbols-outlined text-5xl mb-2">account_balance</span>
                  <p className="font-medium">Chưa có yêu cầu rút tiền nào</p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left min-w-[600px]">
                    <thead className="bg-gray-50 text-gray-500 text-xs uppercase font-semibold">
                      <tr>
                        <th className="px-6 py-3">Ngày yêu cầu</th>
                        <th className="px-6 py-3">Ngân hàng</th>
                        <th className="px-6 py-3">Số tài khoản</th>
                        <th className="px-6 py-3">Số tiền</th>
                        <th className="px-6 py-3">Trạng thái</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100 text-sm">
                      {withdrawals.map(w => {
                        const cfg = withdrawalStatusCfg(w.status);
                        return (
                          <tr key={w.id} className="hover:bg-gray-50/50">
                            <td className="px-6 py-4 font-medium">{fmtDateTime(w.createdAt)}</td>
                            <td className="px-6 py-4">{w.bankName}</td>
                            <td className="px-6 py-4 font-mono text-gray-600">{w.bankAccount}
                              <span className="block text-[11px] text-gray-400">{w.accountHolder}</span>
                            </td>
                            <td className="px-6 py-4 font-bold text-primary">{fmt(w.amount)}</td>
                            <td className="px-6 py-4">
                              <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold ${cfg.cls}`}>
                                <span className="material-symbols-outlined text-xs">{cfg.icon}</span>{cfg.label}
                              </span>
                              {w.processedAt && <p className="text-[11px] text-gray-400 mt-0.5">{fmtDateTime(w.processedAt)}</p>}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>

            {/* Order history */}
            <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
              <div className="px-6 py-4 border-b border-gray-100"><h3 className="font-semibold text-lg">Lịch sử đơn hàng gần đây</h3></div>
              <div className="overflow-x-auto">
                <table className="w-full text-left min-w-[500px]">
                  <thead className="bg-gray-50 text-gray-500 text-xs uppercase font-semibold">
                    <tr>
                      <th className="px-6 py-3">Ngày</th>
                      <th className="px-6 py-3">Mã đơn</th>
                      <th className="px-6 py-3">Trạng thái</th>
                      <th className="px-6 py-3">Số tiền</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 text-sm">
                    {(wallet?.recentTransactions ?? []).map((tx, i) => (
                      <tr key={i} className="hover:bg-gray-50/50">
                        <td className="px-6 py-4 font-medium">{fmtDate(tx.date)}</td>
                        <td className="px-6 py-4 text-gray-500 font-mono">{tx.orderCode}</td>
                        <td className="px-6 py-4">
                          <span className={`px-2 py-0.5 rounded text-xs font-semibold ${tx.status === 'DELIVERED' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-600'}`}>
                            {tx.status === 'DELIVERED' ? 'Hoàn thành' : tx.status}
                          </span>
                        </td>
                        <td className={`px-6 py-4 font-semibold ${tx.status === 'DELIVERED' ? 'text-green-600' : 'text-red-500'}`}>
                          {tx.status === 'DELIVERED' ? '+' : ''}{fmt(tx.amount)}
                        </td>
                      </tr>
                    ))}
                    {(wallet?.recentTransactions ?? []).length === 0 && (
                      <tr><td colSpan={4} className="px-6 py-8 text-center text-gray-400">Chưa có giao dịch</td></tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </>
        )}

        {/* ── Withdrawal Modal ── */}
        {showWithdraw && (
          <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-2xl w-full max-w-md shadow-2xl overflow-hidden">
              {/* Header */}
              <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
                <div className="flex items-center gap-2">
                  <span className="material-symbols-outlined text-primary">payments</span>
                  <h3 className="text-lg font-bold text-gray-900">Yêu cầu rút tiền</h3>
                </div>
                <button onClick={() => setShowWithdraw(false)} className="p-1 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition-colors">
                  <span className="material-symbols-outlined">close</span>
                </button>
              </div>

              {/* Balance hint */}
              <div className="mx-6 mt-4 mb-2 bg-primary/5 border border-primary/20 rounded-xl px-4 py-3 flex items-center justify-between">
                <span className="text-sm text-gray-600 font-medium">Số dư khả dụng</span>
                <span className="text-primary font-bold text-lg">{wallet ? fmt(wallet.availableBalance) : '–'}</span>
              </div>

              <div className="px-6 pb-6 space-y-4 pt-2">
                {/* Amount */}
                <div>
                  <label className="block text-sm font-semibold text-gray-800 mb-1.5">Số tiền muốn rút <span className="text-red-500">*</span></label>
                  <div className="relative">
                    <input
                      type="number"
                      min="100000"
                      step="50000"
                      value={wForm.amount}
                      onChange={e => setWForm(f => ({ ...f, amount: e.target.value }))}
                      placeholder="VD: 1000000"
                      className="w-full px-4 py-2.5 pr-10 rounded-lg border border-gray-200 bg-gray-50 focus:bg-white focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all font-medium"
                    />
                    <span className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm font-semibold">đ</span>
                  </div>
                  <div className="flex gap-2 mt-2 flex-wrap">
                    {[500000, 1000000, 2000000, 5000000].map(amt => (
                      <button key={amt} type="button"
                        onClick={() => setWForm(f => ({ ...f, amount: String(amt) }))}
                        className="text-xs px-2.5 py-1 rounded-full border border-gray-200 bg-gray-50 hover:bg-primary/10 hover:border-primary/40 hover:text-primary font-medium transition-colors"
                      >{fmt(amt)}</button>
                    ))}
                  </div>
                </div>

                {/* Bank */}
                <div>
                  <label className="block text-sm font-semibold text-gray-800 mb-1.5">Ngân hàng <span className="text-red-500">*</span></label>
                  <select
                    value={wForm.bankName}
                    onChange={e => setWForm(f => ({ ...f, bankName: e.target.value }))}
                    className="w-full px-4 py-2.5 rounded-lg border border-gray-200 bg-gray-50 focus:bg-white focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all font-medium"
                  >
                    <option value="">-- Chọn ngân hàng --</option>
                    {BANKS.map(b => <option key={b} value={b}>{b}</option>)}
                  </select>
                </div>

                {/* Account number */}
                <div>
                  <label className="block text-sm font-semibold text-gray-800 mb-1.5">Số tài khoản <span className="text-red-500">*</span></label>
                  <input
                    type="text"
                    value={wForm.bankAccount}
                    onChange={e => setWForm(f => ({ ...f, bankAccount: e.target.value }))}
                    placeholder="VD: 1234567890"
                    className="w-full px-4 py-2.5 rounded-lg border border-gray-200 bg-gray-50 focus:bg-white focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all font-medium"
                  />
                </div>

                {/* Account holder */}
                <div>
                  <label className="block text-sm font-semibold text-gray-800 mb-1.5">Tên chủ tài khoản <span className="text-red-500">*</span></label>
                  <input
                    type="text"
                    value={wForm.accountHolder}
                    onChange={e => setWForm(f => ({ ...f, accountHolder: e.target.value }))}
                    placeholder="VD: NGUYEN VAN A"
                    className="w-full px-4 py-2.5 rounded-lg border border-gray-200 bg-gray-50 focus:bg-white focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all font-medium uppercase"
                  />
                  <p className="text-[11px] text-gray-400 mt-1">Nhập IN HOA đúng với tên trên thẻ ngân hàng</p>
                </div>

                {wError && (
                  <div className="bg-red-50 border border-red-200 rounded-lg px-4 py-2.5 flex items-center gap-2 text-red-600 text-sm font-medium">
                    <span className="material-symbols-outlined text-base">error</span>{wError}
                  </div>
                )}

                <div className="flex gap-3 pt-1">
                  <button
                    onClick={() => setShowWithdraw(false)}
                    className="flex-1 py-2.5 rounded-xl border border-gray-200 text-gray-600 font-semibold hover:bg-gray-50 transition-colors"
                  >Huỷ</button>
                  <button
                    onClick={handleWithdraw}
                    disabled={wSaving}
                    className="flex-1 py-2.5 rounded-xl bg-primary text-white font-bold hover:bg-orange-600 shadow-md shadow-primary/20 transition-all disabled:opacity-60 flex items-center justify-center gap-2"
                  >
                    {wSaving
                      ? <span className="material-symbols-outlined animate-spin text-base">progress_activity</span>
                      : <><span className="material-symbols-outlined text-base">send_money</span>Xác nhận rút</>}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  // =================== PROMOTIONS ===================
  return (
    <div className="p-4 md:p-8 max-w-7xl mx-auto space-y-8 relative">
      {/* Toast */}
      {toast && (
        <div className="fixed top-6 right-6 z-[100] bg-gray-900 text-white px-5 py-3 rounded-xl shadow-2xl text-sm font-semibold animate-[fadeIn_0.2s_ease]">{toast}</div>
      )}

      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 tracking-tight">Khuyến mãi</h1>
          <p className="text-gray-500 mt-1">Tăng doanh số với các voucher hấp dẫn</p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="w-full md:w-auto bg-primary hover:bg-orange-600 text-white px-6 py-3 rounded-xl font-semibold shadow-lg shadow-primary/20 transition-all flex items-center justify-center gap-2"
        >
          <span className="material-symbols-outlined">add_circle</span> Tạo Khuyến mãi
        </button>
      </div>

      {voucherLoading && <div className="flex items-center justify-center h-48"><div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin"></div></div>}

      {!voucherLoading && vouchers.length === 0 && (
        <div className="flex flex-col items-center justify-center py-16 text-gray-400">
          <span className="material-symbols-outlined text-6xl mb-3">sell</span>
          <p className="font-semibold text-lg">Chưa có khuyến mãi nào</p>
          <p className="text-sm mt-1">Bấm "Tạo Khuyến mãi" để bắt đầu</p>
        </div>
      )}

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        {vouchers.map(v => {
          const isActive = v.status === 'ACTIVE';
          return (
            <div key={v.id} className={`bg-white p-6 rounded-2xl border border-gray-200 shadow-sm transition-all relative overflow-hidden group ${!isActive ? 'opacity-60 grayscale' : 'hover:shadow-lg'}`}>
              <div className="flex justify-between items-start mb-4">
                <div className="flex gap-3 items-center">
                  <div className="w-14 h-14 rounded-2xl bg-orange-50 flex items-center justify-center text-primary">
                    <span className="material-symbols-outlined text-3xl">{v.discountType === 'FIXED' ? 'attach_money' : 'percent'}</span>
                  </div>
                  <div>
                    <h3 className="text-lg font-bold">{v.title}</h3>
                    <p className="text-sm text-gray-500 mt-0.5">Mã: <span className="bg-gray-100 px-2 py-0.5 rounded font-mono font-semibold text-gray-800">{v.code}</span></p>
                  </div>
                </div>
                <div
                  className={`relative w-11 h-6 rounded-full cursor-pointer transition-colors shrink-0 ${isActive ? 'bg-primary' : 'bg-gray-300'}`}
                  onClick={() => handleToggle(v.id)}
                >
                  <div className={`absolute top-1 w-4 h-4 bg-white rounded-full shadow-sm transition-all ${isActive ? 'right-1' : 'left-1'}`}></div>
                </div>
              </div>
              <div className="grid grid-cols-3 gap-3 mb-4 text-xs">
                <div>
                  <p className="uppercase font-semibold text-gray-400 tracking-wider mb-1">Giảm</p>
                  <p className="font-bold text-gray-900">{v.discountType === 'PERCENT' ? `${v.discountValue}%` : fmt(v.discountValue)}</p>
                </div>
                <div>
                  <p className="uppercase font-semibold text-gray-400 tracking-wider mb-1">Đã dùng</p>
                  <p className="font-bold text-gray-900">{v.usedCount}{v.maxUsesTotal ? ` / ${v.maxUsesTotal}` : ''}</p>
                </div>
                <div>
                  <p className="uppercase font-semibold text-gray-400 tracking-wider mb-1">Hết hạn</p>
                  <p className="font-bold text-gray-900">{fmtDate(v.endAt)}</p>
                </div>
              </div>
              <div className="flex gap-2 pt-4 border-t border-gray-100">
                <button
                  onClick={() => toggleVoucherPublished(v.id).then(() => setVouchers(vs => vs.map(x => x.id === v.id ? { ...x, isPublished: !x.isPublished } : x)))}
                  className={`flex-1 py-2 rounded-lg text-xs font-semibold border transition-colors ${v.isPublished ? 'border-primary text-primary bg-orange-50' : 'border-gray-200 text-gray-600 hover:bg-gray-50'}`}
                >
                  {v.isPublished ? '✓ Đã hiện' : 'Hiện với KH'}
                </button>
                <button onClick={() => handleDelete(v.id)} className="py-2 px-3 rounded-lg border border-red-100 text-red-500 hover:bg-red-50 text-xs font-semibold transition-colors">
                  <span className="material-symbols-outlined text-sm">delete</span>
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Create Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
          <div className="bg-white w-full max-w-lg rounded-2xl shadow-2xl overflow-hidden">
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
              <h2 className="text-xl font-semibold text-gray-900">Tạo Khuyến Mãi Mới</h2>
              <button onClick={() => setIsModalOpen(false)} className="text-gray-400 hover:text-gray-600 p-1 hover:bg-gray-100 rounded-lg">
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>
            <div className="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
              <div>
                <label className="block text-sm font-semibold text-gray-800 mb-2">Tên chương trình *</label>
                <input value={newV.title} onChange={e => setNewV({...newV, title: e.target.value})}
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 outline-none focus:bg-white focus:border-primary font-medium placeholder:text-gray-400"
                  placeholder="VD: Chào Hè Rực Rỡ" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-800 mb-2">Loại giảm giá</label>
                  <select value={newV.discountType} onChange={e => setNewV({...newV, discountType: e.target.value})}
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 outline-none focus:bg-white focus:border-primary font-medium appearance-none">
                    <option value="PERCENT">Giảm theo %</option>
                    <option value="FIXED">Số tiền cố định</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-800 mb-2">Giá trị</label>
                  <input type="number" value={newV.discountValue} onChange={e => setNewV({...newV, discountValue: e.target.value})}
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 outline-none focus:bg-white focus:border-primary font-medium placeholder:text-gray-400"
                    placeholder={newV.discountType === 'PERCENT' ? '15' : '20000'} />
                </div>
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-800 mb-2">Mã Code *</label>
                <input value={newV.code} onChange={e => setNewV({...newV, code: e.target.value.toUpperCase()})}
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 outline-none focus:bg-white focus:border-primary font-mono placeholder:font-sans placeholder:text-gray-400"
                  placeholder="SUMMER2026" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-800 mb-2">Đơn tối thiểu (đ)</label>
                  <input type="number" value={newV.minOrderAmount} onChange={e => setNewV({...newV, minOrderAmount: e.target.value})}
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 outline-none focus:bg-white focus:border-primary font-medium placeholder:text-gray-400"
                    placeholder="50000" />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-800 mb-2">Giới hạn lượt dùng</label>
                  <input type="number" value={newV.maxUsesTotal} onChange={e => setNewV({...newV, maxUsesTotal: e.target.value})}
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 outline-none focus:bg-white focus:border-primary font-medium placeholder:text-gray-400"
                    placeholder="100" />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-800 mb-2">Ngày bắt đầu</label>
                  <input type="date" value={newV.startAt} onChange={e => setNewV({...newV, startAt: e.target.value})}
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 outline-none focus:bg-white focus:border-primary font-medium" />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-800 mb-2">Ngày kết thúc</label>
                  <input type="date" value={newV.endAt} onChange={e => setNewV({...newV, endAt: e.target.value})}
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 outline-none focus:bg-white focus:border-primary font-medium" />
                </div>
              </div>
            </div>
            <div className="px-6 py-4 bg-gray-50 border-t border-gray-100 flex justify-end gap-3">
              <button onClick={() => setIsModalOpen(false)} className="px-6 py-2.5 rounded-xl border border-gray-200 font-semibold text-sm text-gray-600 hover:bg-white">Hủy</button>
              <button onClick={handleCreate} disabled={saving}
                className="px-6 py-2.5 rounded-xl bg-primary text-white font-semibold text-sm hover:bg-orange-600 shadow-lg shadow-primary/20 disabled:opacity-60 flex items-center gap-2">
                {saving && <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>}
                Tạo ngay
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
