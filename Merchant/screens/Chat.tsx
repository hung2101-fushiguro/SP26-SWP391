import React, { useState, useEffect, useRef } from 'react';

interface Message {
  id: number;
  text: string;
  sender: 'me' | 'other';
  time: string;
}

interface Conversation {
  id: number;
  name: string;
  role: 'Khách hàng' | 'Tài xế';
  avatar: string;
  lastMessage: string;
  time: string;
  unread: number;
  isOnline?: boolean;
  messages: Message[];
}

interface ChatProps {
  initialChatId?: number;
}

export const Chat: React.FC<ChatProps> = ({ initialChatId }) => {
  const [conversations, setConversations] = useState<Conversation[]>([
    {
      id: 1,
      name: 'Nguyễn Văn A',
      role: 'Khách hàng',
      avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=100&q=60',
      lastMessage: 'Cho mình xin thêm tương ớt nha shop',
      time: '12:30',
      unread: 1,
      isOnline: true,
      messages: [
        { id: 1, text: 'Chào bạn, đơn hàng của mình sắp xong chưa ạ?', sender: 'other', time: '12:28' },
        { id: 2, text: 'Dạ chào bạn, bếp đang chuẩn bị rồi ạ. Tầm 5 phút nữa là xong nhé.', sender: 'me', time: '12:29' },
        { id: 3, text: 'Tuyệt vời. Cho mình xin thêm tương ớt nha shop.', sender: 'other', time: '12:30' },
      ]
    },
    {
      id: 2,
      name: 'Trần Văn Tài',
      role: 'Tài xế',
      avatar: 'https://images.unsplash.com/photo-1633332755192-727a05c4013d?auto=format&fit=crop&w=100&q=60',
      lastMessage: 'Tôi đang đợi ở trước quán nhé',
      time: '12:15',
      unread: 2,
      messages: [
        { id: 1, text: 'Alo quán ơi, đơn #CE-4820 xong chưa?', sender: 'other', time: '12:10' },
        { id: 2, text: 'Đang gói bạn ơi, 2 phút nữa nha.', sender: 'me', time: '12:12' },
        { id: 3, text: 'Tôi đang đợi ở trước quán nhé', sender: 'other', time: '12:15' },
      ]
    },
    {
      id: 3,
      name: 'Lê Hoàng C',
      role: 'Khách hàng',
      avatar: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=100&q=60',
      lastMessage: 'Cảm ơn shop nhiều!',
      time: 'Hôm qua',
      unread: 0,
      messages: [
        { id: 1, text: 'Món ăn rất ngon, mình sẽ đánh giá 5 sao.', sender: 'other', time: '19:45' },
        { id: 2, text: 'Cảm ơn bạn nhiều ạ! Mong bạn ủng hộ lần sau nhé.', sender: 'me', time: '19:50' },
        { id: 3, text: 'Cảm ơn shop nhiều!', sender: 'other', time: '20:00' },
      ]
    }
  ]);

  const [activeChatId, setActiveChatId] = useState<number | null>(null);
  const [inputText, setInputText] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [isMobile, setIsMobile] = useState(() => window.innerWidth < 768);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = () => setIsMobile(window.innerWidth < 768);
    window.addEventListener('resize', handler);
    return () => window.removeEventListener('resize', handler);
  }, []);

  // Handle initial navigation param
  useEffect(() => {
    if (initialChatId) {
      setActiveChatId(initialChatId);
    } else {
      // Default to first chat on desktop if not mobile
      if (window.innerWidth >= 768) {
        setActiveChatId(1);
      }
    }
  }, [initialChatId]);

  const activeConversation = conversations.find(c => c.id === activeChatId) || null;

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [activeConversation?.messages, isTyping]);

  const handleSendMessage = (e?: React.FormEvent) => {
    e?.preventDefault();
    if (!inputText.trim() || !activeChatId) return;

    const newMessage: Message = {
      id: Date.now(),
      text: inputText,
      sender: 'me',
      time: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
    };

    setConversations(prev => prev.map(c => 
      c.id === activeChatId 
        ? { ...c, messages: [...c.messages, newMessage], lastMessage: inputText, time: 'Vừa xong' } 
        : c
    ));

    setInputText('');

    // Simulate other person typing
    setTimeout(() => {
       setIsTyping(true);
       setTimeout(() => {
         const replyMessage: Message = {
            id: Date.now() + 1,
            text: "Cảm ơn shop nhé! 🥰",
            sender: 'other',
            time: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
         };
         setConversations(prev => prev.map(c => 
            c.id === activeChatId 
              ? { ...c, messages: [...c.messages, replyMessage], lastMessage: "Cảm ơn shop nhé! 🥰", time: 'Vừa xong' } 
              : c
          ));
          setIsTyping(false);
       }, 2000);
    }, 1000);
  };

  // Mark as read when clicking
  const handleSelectChat = (id: number) => {
    setActiveChatId(id);
    setConversations(conversations.map(c => 
      c.id === id ? { ...c, unread: 0 } : c
    ));
  };

  return (
    <div className="flex flex-1 min-h-0 bg-white overflow-hidden">
      {/* Sidebar List */}
      <div
        className="w-full md:w-80 shrink-0 border-r border-gray-200 flex flex-col"
        style={{ display: isMobile && activeChatId ? 'none' : 'flex' }}
      >
        <div className="p-4 border-b border-gray-100">
          <div className="relative">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">search</span>
            <input 
              type="text" 
              placeholder="Tìm tin nhắn..." 
              className="w-full pl-10 pr-4 py-3 bg-gray-50 border-none rounded-xl text-sm focus:ring-2 focus:ring-primary/20 outline-none transition-all"
            />
          </div>
        </div>
        <div className="flex-1 overflow-y-auto">
          {conversations.map(chat => (
            <div 
              key={chat.id} 
              onClick={() => handleSelectChat(chat.id)}
              className={`p-4 flex gap-3 cursor-pointer hover:bg-gray-50 transition-colors border-l-4 ${activeChatId === chat.id ? 'bg-orange-50/50 border-primary' : 'border-transparent'}`}
            >
              <div className="relative shrink-0">
                <img src={chat.avatar} alt={chat.name} className="w-12 h-12 rounded-full object-cover border border-gray-200" />
                {chat.isOnline && <span className="absolute bottom-0 right-0 w-3.5 h-3.5 bg-green-500 border-2 border-white rounded-full"></span>}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex justify-between items-start mb-1">
                  <h4 className={`text-sm truncate ${chat.unread > 0 ? 'font-bold text-gray-900' : 'font-semibold text-gray-700'}`}>{chat.name}</h4>
                  <span className="text-[10px] text-gray-400 shrink-0 ml-2">{chat.time}</span>
                </div>
                <div className="flex justify-between items-center">
                  <p className={`text-xs truncate ${chat.unread > 0 ? 'text-gray-900 font-semibold' : 'text-gray-500'}`}>{chat.role === 'Tài xế' && '🛵 '}{chat.lastMessage}</p>
                  {chat.unread > 0 && (
                    <span className="ml-2 bg-primary text-white text-[10px] font-semibold px-1.5 py-0.5 rounded-full min-w-[18px] text-center">{chat.unread}</span>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>{/* end sidebar list */}

      {/* Main Chat Area */}
      <div
        className="flex-1 flex flex-col min-h-0 min-w-0 bg-[#f8f7f5]"
        style={{ display: isMobile && !activeChatId ? 'none' : 'flex' }}
      >
        {!activeConversation ? (
          <div className="flex-1 flex flex-col items-center justify-center text-gray-400 bg-white md:bg-transparent">
             <div className="w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mb-4">
                <span className="material-symbols-outlined text-4xl opacity-50">chat_bubble</span>
             </div>
             <p className="font-medium">Chọn một cuộc hội thoại để bắt đầu</p>
          </div>
        ) : (
          <>
            {/* Chat Header */}
            <div className="bg-white/90 backdrop-blur border-b border-gray-200 px-4 md:px-6 py-3 flex items-center justify-between shrink-0">
              <div className="flex items-center gap-3">
                 <div className="md:hidden mr-2 cursor-pointer p-1 -ml-2" onClick={() => setActiveChatId(null)}>
                    <span className="material-symbols-outlined text-gray-500">arrow_back</span>
                 </div>
                 <img src={activeConversation.avatar} className="w-10 h-10 rounded-full object-cover border border-gray-200 shadow-sm" />
                 <div>
                   <h3 className="font-semibold text-gray-900 leading-tight text-base">{activeConversation.name}</h3>
                   <p className="text-xs text-gray-500 flex items-center gap-1 font-medium">
                     {activeConversation.isOnline ? <span className="w-1.5 h-1.5 bg-green-500 rounded-full"></span> : null}
                     {activeConversation.role}
                   </p>
                 </div>
              </div>
              <div className="flex gap-2">
                <button className="w-10 h-10 flex items-center justify-center rounded-full bg-gray-50 hover:bg-gray-100 text-primary transition-colors">
                  <span className="material-symbols-outlined text-xl">call</span>
                </button>
                <button className="w-10 h-10 flex items-center justify-center rounded-full bg-gray-50 hover:bg-gray-100 text-gray-500 transition-colors">
                  <span className="material-symbols-outlined text-xl">more_vert</span>
                </button>
              </div>
            </div>

            {/* Messages List */}
            <div
              className="flex-1 overflow-y-auto no-scrollbar space-y-3"
              style={{ scrollbarWidth: 'none', msOverflowStyle: 'none', padding: '16px' } as React.CSSProperties}
            >
              <div className="text-center mb-6">
                 <span className="text-[10px] font-semibold text-gray-500 bg-gray-200 px-3 py-1 rounded-full uppercase tracking-wider">Hôm nay</span>
              </div>
              
              {activeConversation.messages.map((msg) => {
                 const isMe = msg.sender === 'me';
                 return (
                  <div key={msg.id} className={`flex w-full group ${isMe ? 'justify-end pr-4' : 'justify-start items-end pl-4'}`}>
                    {!isMe && (
                        <img src={activeConversation.avatar} className="w-6 h-6 rounded-full mb-1 mr-2 object-cover border border-gray-200" />
                    )}
                    <div className={`max-w-[68%] md:max-w-[60%] px-4 py-3 shadow-sm relative text-[14px] transition-all hover:shadow-md ${
                      isMe 
                        ? 'bg-primary text-white rounded-[20px] rounded-br-sm' 
                        : 'bg-white text-gray-900 rounded-[20px] rounded-bl-sm'
                    }`}>
                      <p className="leading-relaxed">{msg.text}</p>
                      <div className={`flex items-center justify-end gap-1 mt-1 opacity-70 ${isMe ? 'text-white/80' : 'text-gray-400'}`}>
                          <span className="text-[10px] font-medium">{msg.time}</span>
                          {isMe && <span className="material-symbols-outlined text-[12px] font-semibold">done_all</span>}
                      </div>
                    </div>
                  </div>
                 );
              })}
              
              {isTyping && (
                  <div className="flex w-full justify-start items-end pl-4">
                     <img src={activeConversation.avatar} className="w-6 h-6 rounded-full mb-1 mr-2 object-cover border border-gray-200" />
                     <div className="bg-white px-4 py-3 rounded-[20px] rounded-bl-sm shadow-sm">
                        <div className="flex gap-1">
                           <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
                           <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce delay-100"></div>
                           <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce delay-200"></div>
                        </div>
                     </div>
                  </div>
              )}

              <div ref={messagesEndRef} />
            </div>

            {/* Input Area */}
            <div className="px-3 py-3 bg-white border-t border-gray-200 shrink-0">
               <form onSubmit={handleSendMessage} className="flex items-end gap-1.5">
                 <button type="button" className="p-2 text-gray-400 hover:text-primary hover:bg-gray-50 rounded-full transition-colors shrink-0">
                   <span className="material-symbols-outlined">add_circle</span>
                 </button>
                 <button type="button" className="p-3 text-gray-400 hover:text-primary hover:bg-gray-50 rounded-full transition-colors hidden md:block">
                   <span className="material-symbols-outlined">image</span>
                 </button>
                 <div className="flex-1 bg-gray-100 border border-transparent rounded-3xl px-5 py-3 focus-within:bg-white focus-within:border-primary/50 focus-within:ring-4 focus-within:ring-primary/10 transition-all">
                    <input 
                      type="text" 
                      value={inputText}
                      onChange={(e) => setInputText(e.target.value)}
                      placeholder="Nhập tin nhắn..." 
                      className="w-full bg-transparent border-none outline-none text-sm text-gray-900 placeholder:text-gray-500 font-medium"
                    />
                 </div>
                 <button 
                   type="submit" 
                   disabled={!inputText.trim()}
                   className="p-2.5 bg-primary text-white rounded-full shadow-lg shadow-primary/30 hover:bg-orange-600 hover:scale-110 active:scale-95 transition-all flex items-center justify-center disabled:opacity-50 disabled:cursor-not-allowed shrink-0"
                 >
                   <span className="material-symbols-outlined">send</span>
                 </button>
               </form>
               <div className="flex gap-2 mt-3 overflow-x-auto no-scrollbar pb-1 px-1">
                  {['Đơn hàng của bạn đã sẵn sàng!', 'Cảm ơn bạn đã đặt hàng.', 'Xin lỗi vì sự chậm trễ.'].map((quick, i) => (
                    <button 
                      key={i} 
                      onClick={() => { setInputText(quick); }}
                      className="px-4 py-1.5 bg-gray-50 border border-gray-200 rounded-full text-xs font-semibold text-gray-600 hover:bg-primary/10 hover:text-primary hover:border-primary whitespace-nowrap transition-colors"
                    >
                      {quick}
                    </button>
                  ))}
               </div>
            </div>
          </>
        )}
      </div>{/* end main chat area */}
    </div>
  );
};