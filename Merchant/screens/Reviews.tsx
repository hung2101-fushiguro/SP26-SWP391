import React, { useState, useEffect } from 'react';
import { getReviews, Review as ApiReview, ReviewsResponse } from '../api';

export const Reviews: React.FC = () => {
  const [data, setData] = useState<ReviewsResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'Tất cả' | 'Chưa trả lời' | 'Tiêu cực'>('Tất cả');
  const [replyText, setReplyText] = useState<{ [key: number]: string }>({});
  const [replySent, setReplySent] = useState<{ [key: number]: string }>({});

  useEffect(() => {
    getReviews(1, 50)
      .then(setData)
      .finally(() => setLoading(false));
  }, []);

  const handleReply = (id: number) => {
    if (!replyText[id]) return;
    setReplySent(prev => ({ ...prev, [id]: replyText[id] }));
    const next = { ...replyText };
    delete next[id];
    setReplyText(next);
  };

  const formatDate = (iso: string) => {
    const d = new Date(iso);
    const diffMs = Date.now() - d.getTime();
    const diffDays = Math.floor(diffMs / 86400000);
    if (diffDays === 0) return 'Hôm nay';
    if (diffDays === 1) return 'Hôm qua';
    if (diffDays < 7) return `${diffDays} ngày trước`;
    return d.toLocaleDateString('vi-VN');
  };

  const reviews = data?.items ?? [];

  const filteredReviews = reviews.filter(r => {
    if (filter === 'Chưa trả lời') return !replySent[r.id];
    if (filter === 'Tiêu cực') return r.stars <= 3;
    return true;
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <span className="material-symbols-outlined animate-spin text-4xl text-primary">progress_activity</span>
      </div>
    );
  }

  return (
    <div className="p-4 md:p-8 max-w-5xl mx-auto space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 mb-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 tracking-tight">Đánh giá Khách hàng</h1>
          <p className="text-gray-500 text-sm mt-1">Quản lý phản hồi và danh tiếng</p>
        </div>
        <div className="flex bg-white rounded-lg p-1 border border-gray-200 shadow-sm w-full md:w-auto overflow-x-auto">
          {(['Tất cả', 'Chưa trả lời', 'Tiêu cực'] as const).map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`flex-1 md:flex-none px-4 py-1.5 rounded-md text-sm font-semibold shadow-sm transition-all whitespace-nowrap ${filter === f ? 'bg-primary text-white' : 'text-gray-600 hover:bg-gray-50'}`}
            >{f}</button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm text-center">
          <h3 className="text-4xl font-bold text-gray-900">{data?.avgStars != null ? data.avgStars.toFixed(1) : '—'}</h3>
          <div className="flex justify-center text-yellow-400 my-2">
            {[...Array(5)].map((_, i) => (
              <span key={i} className="material-symbols-outlined fill text-2xl">star</span>
            ))}
          </div>
          <p className="text-gray-500 text-sm font-semibold uppercase tracking-wide">Điểm trung bình</p>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm text-center">
          <h3 className="text-4xl font-bold text-gray-900">{data?.total ?? 0}</h3>
          <p className="text-gray-500 text-sm font-semibold uppercase tracking-wide mt-4">Tổng đánh giá</p>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm text-center">
          <h3 className="text-4xl font-bold text-gray-900">{reviews.length > 0 ? Math.round((reviews.filter(r => r.stars >= 4).length / reviews.length) * 100) : 0}%</h3>
          <p className="text-gray-500 text-sm font-semibold uppercase tracking-wide mt-4">Tích cực</p>
        </div>
      </div>

      <div className="space-y-4">
        {filteredReviews.length === 0 ? (
          <div className="text-center py-12 bg-white rounded-xl border border-dashed border-gray-200">
            <p className="text-gray-500 font-semibold">Không tìm thấy đánh giá nào.</p>
          </div>
        ) : filteredReviews.map((review) => (
          <div key={review.id} className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-3">
              <div className="flex items-center gap-3">
                <div className={`w-10 h-10 rounded-full flex items-center justify-center font-semibold text-white shadow-sm ${review.stars > 3 ? 'bg-green-500' : 'bg-orange-500'}`}>
                  {review.raterName.charAt(0)}
                </div>
                <div>
                  <h4 className="font-semibold text-gray-900">{review.raterName}</h4>
                  <p className="text-xs text-gray-400">{formatDate(review.createdAt)}</p>
                </div>
              </div>
              <div className="flex text-yellow-400 text-sm">
                {[...Array(5)].map((_, i) => (
                  <span key={i} className={`material-symbols-outlined text-lg ${i < review.stars ? 'fill' : 'text-gray-200'}`}>star</span>
                ))}
              </div>
            </div>
            <p className="text-gray-700 mb-4">{review.comment}</p>

            {replySent[review.id] ? (
              <div className="bg-gray-50 p-4 rounded-lg border border-gray-100 flex gap-3 animate-[fadeIn_0.3s_ease-out]">
                <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center shrink-0">
                  <span className="material-symbols-outlined text-white text-sm">storefront</span>
                </div>
                <div>
                  <p className="text-xs font-semibold text-gray-900 mb-1">Phản hồi của bạn</p>
                  <p className="text-sm text-gray-600">{replySent[review.id]}</p>
                </div>
              </div>
            ) : (
              <div className="border-t border-gray-100 pt-3 flex gap-2">
                <input
                  type="text"
                  placeholder="Viết câu trả lời..."
                  value={replyText[review.id] || ''}
                  onChange={(e) => setReplyText({ ...replyText, [review.id]: e.target.value })}
                  className="flex-1 bg-gray-50 border border-gray-200 rounded-lg px-4 py-2 text-sm focus:outline-none focus:border-primary focus:bg-white transition-all"
                />
                <button
                  onClick={() => handleReply(review.id)}
                  disabled={!replyText[review.id]}
                  className="bg-primary hover:bg-orange-600 disabled:bg-gray-200 disabled:text-gray-400 disabled:cursor-not-allowed text-white px-4 py-2 rounded-lg text-sm font-semibold transition-colors shadow-sm"
                >Trả lời</button>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};
