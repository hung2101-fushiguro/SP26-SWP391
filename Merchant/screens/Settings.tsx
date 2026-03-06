import React, { useState, useEffect, useRef } from 'react';
import {
  getSettings, updateSettings, updateBusinessHours, updateAvatarUrl,
  saveAvatarUrl, getAvatarUrl,
  MerchantProfile, BusinessHourDay,
} from '../api';

const DAY_CONFIG: { code: BusinessHourDay['day']; label: string }[] = [
  { code: 'MON', label: 'Thứ 2' },
  { code: 'TUE', label: 'Thứ 3' },
  { code: 'WED', label: 'Thứ 4' },
  { code: 'THU', label: 'Thứ 5' },
  { code: 'FRI', label: 'Thứ 6' },
  { code: 'SAT', label: 'Thứ 7' },
  { code: 'SUN', label: 'Chủ Nhật' },
];

const DEFAULT_HOURS: BusinessHourDay[] = DAY_CONFIG.map(d => ({
  day: d.code,
  open: d.code !== 'SUN',
  from: '09:00',
  to: '22:00',
}));

function parseHours(json?: string | null): BusinessHourDay[] {
  try {
    if (!json) return DEFAULT_HOURS;
    const parsed: BusinessHourDay[] = JSON.parse(json);
    // ensure all 7 days present (fill gaps with default)
    return DAY_CONFIG.map(d => {
      const found = parsed.find(h => h.day === d.code);
      return found ?? { day: d.code, open: d.code !== 'SUN', from: '09:00', to: '22:00' };
    });
  } catch {
    return DEFAULT_HOURS;
  }
}

export const Settings: React.FC = () => {
  const [activeTab, setActiveTab] = useState('Cửa hàng');
  const [profile, setProfile] = useState<MerchantProfile | null>(null);
  const [loading, setLoading] = useState(true);

  // ── Tab: Cửa hàng ──────────────────────────────────
  const [isSaving, setIsSaving] = useState(false);
  const [saveMsg, setSaveMsg] = useState('');
  const [shopName, setShopName] = useState('');
  const [shopPhone, setShopPhone] = useState('');
  const [shopAddress, setShopAddress] = useState('');

  // ── Tab: Giờ mở cửa ────────────────────────────────
  const [hours, setHours] = useState<BusinessHourDay[]>(DEFAULT_HOURS);
  const [isSavingHours, setIsSavingHours] = useState(false);
  const [hoursSaveMsg, setHoursSaveMsg] = useState('');

  // ── Avatar upload ─────────────────────────────────
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(getAvatarUrl());
  const [avatarUploading, setAvatarUploading] = useState(false);
  const [avatarMsg, setAvatarMsg] = useState('');

  useEffect(() => {
    getSettings()
      .then(p => {
        setProfile(p);
        setShopName(p.shopName ?? '');
        setShopPhone(p.shopPhone ?? '');
        setShopAddress(p.shopAddressLine ?? '');
        setHours(parseHours(p.businessHours));
        if (p.avatarUrl) {
          setAvatarPreview(p.avatarUrl);
          saveAvatarUrl(p.avatarUrl);
          window.dispatchEvent(new CustomEvent('ce:avatarUpdated', { detail: p.avatarUrl }));
        }
      })
      .finally(() => setLoading(false));
  }, []);

  const updateHourField = (
    idx: number,
    field: 'open' | 'from' | 'to',
    value: boolean | string,
  ) => {
    setHours(prev => prev.map((h, i) => i === idx ? { ...h, [field]: value } : h));
  };

  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 5 * 1024 * 1024) {
      setAvatarMsg('Ảnh quá lớn. Vui lòng chọn ảnh dưới 5MB.');
      return;
    }
    // Hiện preview ngay lập tức qua object URL
    const objectUrl = URL.createObjectURL(file);
    setAvatarPreview(objectUrl);
    setAvatarMsg('');

    const reader = new FileReader();
    reader.onload = () => {
      const result = reader.result as string;
      const img = new Image();
      img.onload = async () => {
        // Resize xuống tối đa 256x256
        const MAX = 256;
        const ratio = Math.min(MAX / img.width, MAX / img.height, 1);
        const canvas = document.createElement('canvas');
        canvas.width = Math.round(img.width * ratio);
        canvas.height = Math.round(img.height * ratio);
        canvas.getContext('2d')!.drawImage(img, 0, 0, canvas.width, canvas.height);
        const dataUrl = canvas.toDataURL('image/jpeg', 0.85);
        setAvatarPreview(dataUrl);   // đổi sang base64 đã nén
        setAvatarUploading(true);
        try {
          await updateAvatarUrl(dataUrl);
          saveAvatarUrl(dataUrl);
          window.dispatchEvent(new CustomEvent('ce:avatarUpdated', { detail: dataUrl }));
          setAvatarMsg('Đã cập nhật ảnh đại diện!');
          setTimeout(() => setAvatarMsg(''), 3000);
        } catch {
          setAvatarMsg('Tải ảnh thất bại. Vui lòng thử lại.');
          setAvatarPreview(getAvatarUrl()); // hoàn tác preview
        } finally {
          setAvatarUploading(false);
          URL.revokeObjectURL(objectUrl);
        }
      };
      img.onerror = () => setAvatarMsg('Định dạng ảnh không hợp lệ.');
      img.src = result;
    };
    reader.readAsDataURL(file);
  };

  const handleSave = async () => {
    setIsSaving(true);
    setSaveMsg('');
    try {
      const updated = await updateSettings({ shopName, shopPhone, shopAddressLine: shopAddress });
      setProfile(updated);
      setSaveMsg('Đã lưu thành công!');
      setTimeout(() => setSaveMsg(''), 3000);
    } catch {
      setSaveMsg('Lưu thất bại. Vui lòng thử lại.');
    } finally {
      setIsSaving(false);
    }
  };

  const handleSaveHours = async () => {
    setIsSavingHours(true);
    setHoursSaveMsg('');
    try {
      const updated = await updateBusinessHours(hours);
      setProfile(updated);
      setHours(parseHours(updated.businessHours));
      setHoursSaveMsg('Đã lưu giờ mở cửa!');
      setTimeout(() => setHoursSaveMsg(''), 3000);
    } catch {
      setHoursSaveMsg('Lưu thất bại. Vui lòng thử lại.');
    } finally {
      setIsSavingHours(false);
    }
  };

  const tabs = ['Cửa hàng', 'Giờ mở cửa', 'Thông báo', 'Bảo mật'];

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <span className="material-symbols-outlined animate-spin text-4xl text-primary">progress_activity</span>
      </div>
    );
  }

  return (
    <div className="p-4 md:p-8 max-w-4xl mx-auto">
      <h1 className="text-3xl font-bold text-gray-900 tracking-tight mb-6">Cài đặt</h1>

      <div className="flex gap-4 md:gap-8 border-b border-gray-200 mb-8 overflow-x-auto no-scrollbar">
        {tabs.map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`pb-4 text-sm font-semibold transition-colors border-b-2 whitespace-nowrap ${activeTab === tab ? 'border-primary text-primary' : 'border-transparent text-gray-500 hover:text-gray-800'}`}
          >{tab}</button>
        ))}
      </div>

      <div className="bg-white border border-gray-200 rounded-2xl p-6 md:p-8 shadow-sm">
        {activeTab === 'Cửa hàng' && (
          <div className="space-y-6">
            <div className="flex flex-col md:flex-row items-center gap-6">
              {/* Avatar */}
              <div className="relative group shrink-0">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  className="hidden"
                  onChange={handleAvatarChange}
                />
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={avatarUploading}
                  className="w-24 h-24 rounded-full overflow-hidden border-2 border-dashed border-gray-300 hover:border-primary transition-colors relative block"
                  title="Đổi ảnh đại diện"
                >
                  {avatarPreview ? (
                    <img src={avatarPreview} alt="avatar" className="w-full h-full object-cover" />
                  ) : (
                    <span className="w-full h-full flex items-center justify-center bg-gray-100">
                      <span className="material-symbols-outlined text-gray-400 text-3xl">storefront</span>
                    </span>
                  )}
                  <span className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center rounded-full">
                    {avatarUploading
                      ? <span className="material-symbols-outlined text-white animate-spin">progress_activity</span>
                      : <span className="material-symbols-outlined text-white">photo_camera</span>}
                  </span>
                </button>
                {avatarMsg && (
                  <p className={`absolute -bottom-6 left-1/2 -translate-x-1/2 text-[11px] font-semibold whitespace-nowrap ${
                    avatarMsg.includes('thất bại') || avatarMsg.includes('lớn') ? 'text-red-500' : 'text-green-600'
                  }`}>{avatarMsg}</p>
                )}
              </div>
              <div className="text-center md:text-left">
                <h3 className="font-semibold text-lg">{profile?.shopName || 'Cửa hàng'}</h3>
                <p className="text-sm text-gray-500">{profile?.email}</p>
                <p className={`text-xs mt-1 font-semibold ${profile?.shopStatus === 'ACTIVE' ? 'text-green-600' : 'text-orange-500'}`}>{profile?.shopStatus === 'ACTIVE' ? '● Đang hoạt động' : '● Tạm ngưng'}</p>
                <p className="text-[11px] text-gray-400 mt-1">Nhấn vào ảnh để thay đổi (tối đa 5MB)</p>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="md:col-span-2">
                <label className="block text-sm font-semibold text-gray-800 mb-2">Tên Cửa hàng</label>
                <input type="text" value={shopName} onChange={e => setShopName(e.target.value)} className="w-full px-4 py-2.5 rounded-lg border border-gray-200 bg-gray-50 focus:bg-white focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all text-gray-900 font-medium" />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-800 mb-2">Số điện thoại</label>
                <input type="text" value={shopPhone} onChange={e => setShopPhone(e.target.value)} className="w-full px-4 py-2.5 rounded-lg border border-gray-200 bg-gray-50 focus:bg-white focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all text-gray-900 font-medium" />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-800 mb-2">Email</label>
                <input type="email" value={profile?.email ?? ''} disabled className="w-full px-4 py-2.5 rounded-lg border border-gray-200 bg-gray-100 text-gray-500 font-medium outline-none cursor-not-allowed" />
              </div>
              <div className="md:col-span-2">
                <label className="block text-sm font-semibold text-gray-800 mb-2">Địa chỉ</label>
                <input type="text" value={shopAddress} onChange={e => setShopAddress(e.target.value)} className="w-full px-4 py-2.5 rounded-lg border border-gray-200 bg-gray-50 focus:bg-white focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all text-gray-900 font-medium" />
              </div>
            </div>

            {saveMsg && (
              <p className={`text-sm font-semibold ${saveMsg.includes('thành công') ? 'text-green-600' : 'text-red-500'}`}>{saveMsg}</p>
            )}

            <div className="flex justify-end pt-4">
              <button onClick={handleSave} className="bg-primary text-white px-6 py-3 rounded-lg font-semibold hover:bg-orange-600 shadow-md min-w-[140px] flex justify-center disabled:opacity-60" disabled={isSaving}>
                {isSaving ? <span className="material-symbols-outlined animate-spin text-sm">progress_activity</span> : 'Lưu thay đổi'}
              </button>
            </div>
          </div>
        )}

        {activeTab === 'Giờ mở cửa' && (
          <div className="space-y-3">
            <p className="text-sm text-gray-500 mb-2">
              Cấu hình giờ hoạt động của cửa hàng. Tắt toggle để đánh dấu ngày nghỉ.
            </p>

            {DAY_CONFIG.map((d, idx) => {
              const h = hours[idx];
              return (
                <div
                  key={d.code}
                  className={`flex flex-col sm:flex-row items-center justify-between p-4 border rounded-xl gap-3 transition-colors ${
                    h.open ? 'bg-white border-gray-200' : 'bg-gray-50 border-gray-100'
                  }`}
                >
                  {/* Toggle + Day name */}
                  <div className="flex items-center gap-3 w-full sm:w-auto">
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        className="sr-only peer"
                        checked={h.open}
                        onChange={e => updateHourField(idx, 'open', e.target.checked)}
                      />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-green-500" />
                    </label>
                    <span className={`font-semibold w-24 ${h.open ? 'text-gray-900' : 'text-gray-400 line-through'}`}>
                      {d.label}
                    </span>
                    {!h.open && (
                      <span className="text-xs font-medium text-red-400 bg-red-50 px-2 py-0.5 rounded-full">Nghỉ</span>
                    )}
                  </div>

                  {/* Time inputs */}
                  <div className={`flex items-center gap-2 w-full sm:w-auto justify-end transition-opacity ${!h.open ? 'opacity-40 pointer-events-none' : ''}`}>
                    <div className="flex flex-col items-center">
                      <span className="text-[10px] text-gray-400 mb-0.5">Mở cửa</span>
                      <input
                        type="time"
                        value={h.from}
                        onChange={e => updateHourField(idx, 'from', e.target.value)}
                        className="bg-white border border-gray-200 rounded-lg px-3 py-1.5 text-sm font-medium outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all"
                      />
                    </div>
                    <span className="text-gray-400 mt-4 font-bold">→</span>
                    <div className="flex flex-col items-center">
                      <span className="text-[10px] text-gray-400 mb-0.5">Đóng cửa</span>
                      <input
                        type="time"
                        value={h.to}
                        onChange={e => updateHourField(idx, 'to', e.target.value)}
                        className="bg-white border border-gray-200 rounded-lg px-3 py-1.5 text-sm font-medium outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all"
                      />
                    </div>
                  </div>
                </div>
              );
            })}

            {/* Quick-fill helpers */}
            <div className="flex flex-wrap gap-2 pt-2">
              <span className="text-xs text-gray-400 self-center mr-1">Điền nhanh:</span>
              {[
                { label: '09:00 – 22:00', from: '09:00', to: '22:00' },
                { label: '08:00 – 21:00', from: '08:00', to: '21:00' },
                { label: '10:00 – 23:00', from: '10:00', to: '23:00' },
              ].map(preset => (
                <button
                  key={preset.label}
                  type="button"
                  onClick={() =>
                    setHours(prev =>
                      prev.map(h => h.open ? { ...h, from: preset.from, to: preset.to } : h)
                    )
                  }
                  className="text-xs px-3 py-1 rounded-full border border-gray-200 bg-gray-50 hover:bg-primary/10 hover:border-primary/40 hover:text-primary font-medium transition-colors"
                >
                  {preset.label}
                </button>
              ))}
            </div>

            {hoursSaveMsg && (
              <p className={`text-sm font-semibold ${hoursSaveMsg.includes('thất bại') ? 'text-red-500' : 'text-green-600'}`}>
                {hoursSaveMsg}
              </p>
            )}

            <div className="flex justify-end pt-2">
              <button
                onClick={handleSaveHours}
                disabled={isSavingHours}
                className="bg-primary text-white px-6 py-3 rounded-lg font-semibold hover:bg-orange-600 shadow-md min-w-[160px] flex justify-center disabled:opacity-60"
              >
                {isSavingHours
                  ? <span className="material-symbols-outlined animate-spin text-sm">progress_activity</span>
                  : 'Lưu giờ mở cửa'}
              </button>
            </div>
          </div>
        )}

        {activeTab === 'Thông báo' && (
          <div className="space-y-6">
            {[
              { label: 'Đơn hàng mới', desc: 'Nhận thông báo khi có đơn mới' },
              { label: 'Đơn hủy', desc: 'Cảnh báo khi khách hủy đơn' },
              { label: 'Đánh giá mới', desc: 'Khi khách để lại phản hồi' },
              { label: 'Báo cáo tổng hợp', desc: 'Báo cáo hàng ngày qua email' },
            ].map((item, i) => (
              <div key={i} className="flex items-center justify-between py-4 border-b border-gray-100 last:border-0">
                <div>
                  <p className="font-semibold text-gray-900">{item.label}</p>
                  <p className="text-sm text-gray-500">{item.desc}</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input type="checkbox" defaultChecked className="sr-only peer" />
                  <div className="w-11 h-6 bg-gray-200 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
                </label>
              </div>
            ))}
          </div>
        )}

        {activeTab === 'Bảo mật' && (
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-semibold text-gray-800 mb-2">Mật khẩu hiện tại</label>
              <input type="password" className="w-full px-4 py-2.5 rounded-lg border border-gray-200 bg-gray-50 outline-none focus:border-primary focus:ring-4 focus:ring-primary/10 transition-all" placeholder="••••••••" />
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-800 mb-2">Mật khẩu mới</label>
              <input type="password" className="w-full px-4 py-2.5 rounded-lg border border-gray-200 bg-gray-50 outline-none focus:border-primary focus:ring-4 focus:ring-primary/10 transition-all" placeholder="••••••••" />
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-800 mb-2">Xác nhận mật khẩu mới</label>
              <input type="password" className="w-full px-4 py-2.5 rounded-lg border border-gray-200 bg-gray-50 outline-none focus:border-primary focus:ring-4 focus:ring-primary/10 transition-all" placeholder="••••••••" />
            </div>
            <div className="flex justify-end pt-4">
              <button className="bg-primary text-white px-6 py-3 rounded-lg font-semibold hover:bg-orange-600 shadow-md">Đổi mật khẩu</button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
