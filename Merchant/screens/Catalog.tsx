import React, { useState, useEffect } from 'react';
import {
  getCategories, getMenuItems, createMenuItem,
  updateMenuItem as apiUpdateMenuItem,
  toggleMenuItemAvailability,
  deleteMenuItem as apiDeleteMenuItem,
  Category, MenuItemAPI,
} from '../api';

type ItemForm = { name: string; price: string; categoryId: number; description: string; imageUrl: string };
const emptyForm = (defaultCatId = 0): ItemForm => ({ name: '', price: '', categoryId: defaultCatId, description: '', imageUrl: '' });
const fmt = (p: number) => new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(p);

export const Catalog: React.FC = () => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<MenuItemAPI | null>(null);
  const [activeCategoryId, setActiveCategoryId] = useState<number | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [menuItems, setMenuItems] = useState<MenuItemAPI[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState<ItemForm>(emptyForm());

  useEffect(() => {
    Promise.all([getCategories(), getMenuItems()])
      .then(([cats, items]) => {
        setCategories(cats);
        if (cats.length > 0) setForm(emptyForm(cats[0].id));
        setMenuItems(items);
      })
      .finally(() => setLoading(false));
  }, []);

  const openAdd = () => {
    setEditingItem(null);
    setForm(emptyForm(categories[0]?.id ?? 0));
    setIsModalOpen(true);
  };

  const openEdit = (item: MenuItemAPI) => {
    setEditingItem(item);
    setForm({ name: item.name, price: String(item.price), categoryId: item.categoryId, description: item.description ?? '', imageUrl: item.imageUrl ?? '' });
    setIsModalOpen(true);
  };

  const closeModal = () => { setIsModalOpen(false); setEditingItem(null); };

  const toggleItemStatus = async (id: number, current: boolean) => {
    try {
      await toggleMenuItemAvailability(id, !current);
      setMenuItems(prev => prev.map(item => item.id === id ? { ...item, available: !current } : item));
    } catch { alert('Không thể cập nhật trạng thái.'); }
  };

  const deleteItem = async (id: number) => {
    if (!window.confirm('Bạn có chắc chắn muốn xóa món này?')) return;
    try {
      await apiDeleteMenuItem(id);
      setMenuItems(prev => prev.filter(item => item.id !== id));
    } catch { alert('Không thể xóa món.'); }
  };

  const handleSave = async () => {
    if (!form.name || !form.price || !form.categoryId) return;
    setSaving(true);
    try {
      const payload = { categoryId: form.categoryId, name: form.name, description: form.description, price: parseFloat(form.price), imageUrl: form.imageUrl || undefined };
      if (editingItem) {
        const updated = await apiUpdateMenuItem(editingItem.id, { ...payload, isAvailable: editingItem.available });
        setMenuItems(prev => prev.map(i => i.id === editingItem.id ? updated : i));
      } else {
        const created = await createMenuItem(payload);
        setMenuItems(prev => [created, ...prev]);
      }
      setForm(emptyForm(categories[0]?.id ?? 0));
      closeModal();
    } catch { alert(editingItem ? 'Không thể cập nhật món.' : 'Không thể thêm món.'); }
    finally { setSaving(false); }
  };

  const catName = (id: number) => categories.find(c => c.id === id)?.name ?? '';
  const filteredItems = activeCategoryId === null ? menuItems : menuItems.filter(i => i.categoryId === activeCategoryId);

  if (loading) return (
    <div className="flex items-center justify-center h-full">
      <span className="material-symbols-outlined animate-spin text-4xl text-primary">progress_activity</span>
    </div>
  );

  return (
    <div className="p-4 md:p-8 max-w-7xl mx-auto relative h-full">
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 mb-8">
        <div>
          <h1 className="text-2xl md:text-3xl font-bold text-gray-900 tracking-tight">Quản lý Thực đơn</h1>
          <p className="text-gray-500 text-sm mt-1">Quản lý món ăn và trạng thái phục vụ</p>
        </div>
        <button onClick={openAdd} className="w-full md:w-auto flex items-center justify-center gap-2 bg-primary hover:bg-orange-600 text-white px-6 py-3 rounded-xl font-semibold shadow-lg shadow-primary/20 transition-all">
          <span className="material-symbols-outlined">add_circle</span>
          Thêm món mới
        </button>
      </div>

      {/* Category tabs */}
      <div className="flex gap-2 overflow-x-auto pb-4 mb-4 no-scrollbar">
        <button
          onClick={() => setActiveCategoryId(null)}
          className={`px-5 py-2.5 rounded-xl text-sm font-semibold whitespace-nowrap transition-all ${activeCategoryId === null ? 'bg-primary text-white shadow-md' : 'bg-white text-gray-500 hover:bg-gray-100 border border-transparent'}`}
        >
          Tất cả
        </button>
        {categories.map(cat => (
          <button
            key={cat.id}
            onClick={() => setActiveCategoryId(cat.id)}
            className={`px-5 py-2.5 rounded-xl text-sm font-semibold whitespace-nowrap transition-all ${activeCategoryId === cat.id ? 'bg-primary text-white shadow-md' : 'bg-white text-gray-500 hover:bg-gray-100 border border-transparent'}`}
          >
            {cat.name}
          </button>
        ))}
      </div>

      {/* Item grid */}
      {filteredItems.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-20 bg-white rounded-2xl border border-dashed border-gray-300">
          <span className="material-symbols-outlined text-6xl text-gray-200 mb-4">restaurant_menu</span>
          <p className="text-gray-500 font-medium">Không tìm thấy món nào</p>
          <button onClick={openAdd} className="mt-4 text-primary font-semibold hover:underline">Thêm món ngay</button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {filteredItems.map(item => (
            <div key={item.id} className="bg-white rounded-2xl border border-gray-200 overflow-hidden shadow-sm group hover:shadow-xl hover:border-primary/20 transition-all relative">
              <div className="h-48 overflow-hidden relative bg-gray-100">
                {item.imageUrl
                  ? <img src={item.imageUrl} alt={item.name} className={`w-full h-full object-cover transition-transform duration-700 group-hover:scale-110 ${!item.available ? 'grayscale opacity-75' : ''}`} loading="lazy" />
                  : <div className="w-full h-full flex items-center justify-center"><span className="material-symbols-outlined text-6xl text-gray-300">restaurant</span></div>
                }
                {/* Hover action buttons */}
                <div className="absolute top-2 right-2 flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button onClick={() => openEdit(item)} title="Sửa món" className="p-2 bg-white/90 rounded-lg hover:text-primary backdrop-blur-sm shadow-sm hover:scale-110 transition-transform">
                    <span className="material-symbols-outlined text-sm">edit</span>
                  </button>
                  <button onClick={() => deleteItem(item.id)} title="Xóa món" className="p-2 bg-white/90 rounded-lg hover:text-red-500 backdrop-blur-sm shadow-sm hover:scale-110 transition-transform">
                    <span className="material-symbols-outlined text-sm">delete</span>
                  </button>
                </div>
                {!item.available && (
                  <div className="absolute inset-0 bg-black/40 flex items-center justify-center backdrop-blur-[1px]">
                    <span className="bg-white/95 px-3 py-1 rounded-full text-xs font-semibold uppercase shadow-sm text-gray-800">Hết hàng</span>
                  </div>
                )}
                <div className="absolute top-2 left-2">
                  <span className="bg-black/50 backdrop-blur-md text-white text-[10px] font-semibold px-2 py-1 rounded-lg uppercase tracking-wide border border-white/10">{catName(item.categoryId)}</span>
                </div>
              </div>
              <div className="p-5">
                <h4 className="font-semibold text-gray-900 line-clamp-2 leading-tight text-base group-hover:text-primary transition-colors mb-1">{item.name}</h4>
                {item.description && <p className="text-gray-400 text-xs line-clamp-1 mb-2">{item.description}</p>}
                <p className="text-gray-900 font-bold text-lg mb-4">{fmt(item.price)}</p>
                <div className="flex items-center justify-between pt-4 border-t border-gray-100">
                  <div className="flex items-center gap-2">
                    <span className={`w-2 h-2 rounded-full ${item.available ? 'bg-green-500' : 'bg-gray-300'}`}></span>
                    <span className={`text-xs font-semibold uppercase ${item.available ? 'text-green-700' : 'text-gray-400'}`}>{item.available ? 'Đang bán' : 'Tạm ngưng'}</span>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input type="checkbox" checked={item.available} onChange={() => toggleItemStatus(item.id, item.available)} className="sr-only peer" />
                    <div className="w-9 h-5 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-primary shadow-inner"></div>
                  </label>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add / Edit modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white w-full max-w-2xl rounded-2xl shadow-2xl flex flex-col max-h-[90vh] overflow-hidden">
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
              <div className="flex items-center gap-3">
                <span className={`material-symbols-outlined ${editingItem ? 'text-primary' : 'text-green-600'}`}>{editingItem ? 'edit' : 'add_circle'}</span>
                <h2 className="text-xl font-semibold text-gray-900">{editingItem ? 'Sửa món ăn' : 'Thêm món mới'}</h2>
              </div>
              <button onClick={closeModal} className="text-gray-400 hover:text-gray-600 p-1 hover:bg-gray-100 rounded-lg transition-colors">
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>
            <div className="flex-1 overflow-y-auto p-6">
              <div className="grid grid-cols-2 gap-4">
                <div className="col-span-2">
                  <label className="block text-sm font-semibold text-gray-800 mb-1.5">Tên món <span className="text-red-500">*</span></label>
                  <input type="text" autoFocus className="w-full rounded-xl border border-gray-300 bg-white p-3 text-sm focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all font-medium" placeholder="Ví dụ: Phở Bò Đặc Biệt" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-800 mb-1.5">Danh mục <span className="text-red-500">*</span></label>
                  <div className="relative">
                    <select className="w-full rounded-xl border border-gray-300 bg-white p-3 text-sm focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all appearance-none font-medium" value={form.categoryId} onChange={e => setForm({ ...form, categoryId: Number(e.target.value) })}>
                      {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                    </select>
                    <span className="material-symbols-outlined absolute right-3 top-3 text-gray-500 pointer-events-none text-sm">expand_more</span>
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-800 mb-1.5">Giá (VNĐ) <span className="text-red-500">*</span></label>
                  <input type="number" min="0" className="w-full rounded-xl border border-gray-300 bg-white p-3 text-sm focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all font-medium" placeholder="0" value={form.price} onChange={e => setForm({ ...form, price: e.target.value })} />
                </div>
                <div className="col-span-2">
                  <label className="block text-sm font-semibold text-gray-800 mb-1.5">URL ảnh (tuỳ chọn)</label>
                  <input type="url" className="w-full rounded-xl border border-gray-300 bg-white p-3 text-sm focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all" placeholder="https://..." value={form.imageUrl} onChange={e => setForm({ ...form, imageUrl: e.target.value })} />
                  {form.imageUrl && <img src={form.imageUrl} alt="preview" className="mt-2 h-20 w-auto rounded-lg object-cover border" onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} />}
                </div>
                <div className="col-span-2">
                  <label className="block text-sm font-semibold text-gray-800 mb-1.5">Mô tả</label>
                  <textarea className="w-full rounded-xl border border-gray-300 bg-white p-3 text-sm focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition-all resize-none" rows={3} placeholder="Thành phần, hương vị đặc trưng..." value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} />
                </div>
              </div>
            </div>
            <div className="px-6 py-4 bg-gray-50 border-t border-gray-100 flex justify-end gap-3">
              <button onClick={closeModal} className="px-6 py-3 rounded-xl border border-gray-300 font-semibold text-sm text-gray-600 hover:bg-white transition-colors">Hủy</button>
              <button onClick={handleSave} disabled={saving || !form.name.trim() || !form.price || !form.categoryId} className="px-8 py-3 rounded-xl bg-primary text-white font-semibold text-sm hover:bg-orange-600 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg shadow-primary/30 transition-all hover:-translate-y-0.5">
                {saving ? 'Đang lưu...' : (editingItem ? 'Cập nhật' : 'Lưu món')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
