import React, { useState, useEffect, useRef } from 'react';
import { Screen } from '../types';
import { login as apiLogin, saveSession, googleLogin, forgotPassword, resetPassword } from '../api';

declare const window: Window & {
  google?: {
    accounts: {
      id: {
        initialize: (cfg: object) => void;
        renderButton: (el: HTMLElement, opts: object) => void;
        prompt: () => void;
      };
    };
  };
};

export const Onboarding: React.FC<{ screen: Screen; onNavigate: (s: Screen) => void }> = ({ screen, onNavigate }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const googleBtnRef = useRef<HTMLDivElement>(null);

  const [fpPhone, setFpPhone] = useState('');
  const [fpStep, setFpStep] = useState<1 | 2>(1);
  const [fpOtp, setFpOtp] = useState('');
  const [fpNewPass, setFpNewPass] = useState('');
  const [fpConfirm, setFpConfirm] = useState('');
  const [fpLoading, setFpLoading] = useState(false);
  const [fpError, setFpError] = useState('');
  const [fpSuccess, setFpSuccess] = useState('');

  // Google Sign-Up: pre-filled profile from Google token
  const [googleProfile, setGoogleProfile] = useState<{ email: string; name: string } | null>(null);
  // registration form fields
  const [regName, setRegName] = useState('');
  const [regEmail, setRegEmail] = useState('');

  useEffect(() => {
    if (screen !== Screen.LOGIN) return;
    const tryRender = () => {
      if (!window.google || !googleBtnRef.current) return;
      window.google.accounts.id.initialize({
        client_id: (import.meta as any).env?.VITE_GOOGLE_CLIENT_ID ?? '791985931467-agv6l5lr044fihqsqbba65dp028cvdqc.apps.googleusercontent.com',
        callback: handleGoogleCallback,
      });
      const w = googleBtnRef.current!.offsetWidth || 400;
      window.google.accounts.id.renderButton(googleBtnRef.current!, {
        theme: 'outline', size: 'large', width: w, text: 'continue_with', locale: 'vi',
      });
    };
    tryRender();
    const t = setInterval(() => { if (window.google) { tryRender(); clearInterval(t); } }, 300);
    return () => clearInterval(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [screen]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const result = await apiLogin(email.trim(), password);
      saveSession(result.token, result.merchantId, result.name, result.shopName);
      onNavigate(Screen.DASHBOARD);
    } catch {
      setError('Email hoặc mật khẩu không chính xác.');
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleCallback = async (response: { credential: string }) => {
    setError('');
    setLoading(true);
    try {
      const result = await googleLogin(response.credential);
      saveSession(result.token, result.merchantId, result.name, result.shopName);
      onNavigate(Screen.DASHBOARD);
    } catch (err: any) {
      if (err?.notRegistered) {
        // Email not yet a merchant → pre-fill and redirect to registration
        const profile = { email: err.email ?? '', name: err.name ?? '' };
        setGoogleProfile(profile);
        setRegName(profile.name);
        setRegEmail(profile.email);
        onNavigate(Screen.REGISTER_STEP_1);
      } else {
        setError('Đăng nhập Google thất bại. Vui lòng thử lại.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleForgotSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setFpError('');
    if (!fpPhone.trim()) { setFpError('Vui lòng nhập số điện thoại.'); return; }
    setFpLoading(true);
    try {
      await forgotPassword(fpPhone.trim());
      setFpStep(2);
    } catch (err: any) {
      setFpError(err?.message ?? 'Không tìm thấy tài khoản với số điện thoại này.');
    } finally {
      setFpLoading(false);
    }
  };

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setFpError('');
    if (!fpOtp.trim() || fpOtp.length !== 6) { setFpError('Mã OTP phải gồm 6 chữ số.'); return; }
    if (!fpNewPass || fpNewPass.length < 6) { setFpError('Mật khẩu mới phai co it nhat 6 ky tu.'); return; }
    if (fpNewPass !== fpConfirm) { setFpError('Mật khẩu xác nhận không khớp.'); return; }
    setFpLoading(true);
    try {
      await resetPassword(fpPhone.trim(), fpOtp.trim(), fpNewPass);
      setFpSuccess('Đặt lại mật khẩu thanh cong! Dang chuyen ve dang nhap...');
      setTimeout(() => {
        setFpPhone(''); setFpOtp(''); setFpNewPass(''); setFpConfirm('');
        setFpStep(1); setFpSuccess('');
        onNavigate(Screen.LOGIN);
      }, 2000);
    } catch (err: any) {
      setFpError(err?.message ?? 'Mã OTP không đúng hoặc đã hết hạn.');
    } finally {
      setFpLoading(false);
    }
  };

  if (screen === Screen.FORGOT_PASSWORD) {
    return (
      <div className= "flex min-h-screen w-full items-center justify-center bg-gray-50 p-4" >
      <div className="w-full max-w-md bg-white rounded-2xl shadow-xl p-8 space-y-6" >
        <button
            onClick={ () => { setFpStep(1); setFpError(''); setFpSuccess(''); onNavigate(Screen.LOGIN); } }
    className = "flex items-center gap-1 text-sm text-gray-500 hover:text-gray-800 font-medium transition-colors"
      >
      <span className="material-symbols-outlined text-base" > arrow_back </span>
            Quay lại đăng nhập
      </button>
      < div >
      <h2 className="text-3xl font-bold text-gray-900 mb-1" > Quên mật khẩu </h2>
        < p className = "text-gray-500 text-sm" >
          { fpStep === 1
          ? 'Nhập số điện thoại đã đăng ký để nhận mã OTP.'
          : `Nhập mã OTP đã gửi tới ${fpPhone} và mật khẩu mới.`
  }
  </p>
    </div>
    < div className = "flex gap-2" >
      {
        [1, 2].map(s => (
          <div key= { s } className = {`h-1.5 flex-1 rounded-full transition-all ${s <= fpStep ? 'bg-primary' : 'bg-gray-200'}`} />
            ))}
</div>
{
  fpSuccess && (
    <div className="p-4 bg-green-50 border border-green-200 rounded-xl text-green-800 text-sm font-medium flex items-center gap-2" >
      <span className="material-symbols-outlined text-sm" > check_circle </span>
  { fpSuccess }
  </div>
          )
}
{
  fpError && (
    <p className="text-red-500 text-sm font-medium flex items-center gap-1" >
      <span className="material-symbols-outlined text-sm" > error </span>
  { fpError }
  </p>
          )
}
{
  fpStep === 1 && (
    <form onSubmit={ handleForgotSendOtp } className = "space-y-4" >
      <div>
      <label className="block text-sm font-semibold text-gray-800 mb-2" > Số điện thoại </label>
        < input
  type = "tel"
  value = { fpPhone }
  onChange = { e => setFpPhone(e.target.value) }
  placeholder = "0901234567"
  className = "w-full h-12 px-4 rounded-xl border border-gray-200 bg-gray-50 text-gray-900 focus:bg-white focus:ring-4 focus:ring-primary/10 focus:border-primary outline-none transition-all placeholder:text-gray-400"
  autoFocus
    />
    </div>
    < button
  type = "submit"
  disabled = { fpLoading }
  className = "w-full h-12 bg-primary hover:bg-orange-600 disabled:opacity-60 text-white font-semibold rounded-xl shadow-lg shadow-primary/20 transition-all flex items-center justify-center gap-2"
    >
  {
    fpLoading
      ?<>< span className = "material-symbols-outlined animate-spin text-xl" > progress_activity < /span><span>Đang gửi...</span > </>
                  : 'Gửi mã OTP'
}
</button>
  </form>
          )}
{
  fpStep === 2 && (
    <form onSubmit={ handleResetPassword } className = "space-y-4" >
      <div>
      <label className="block text-sm font-semibold text-gray-800 mb-2" > Mã OTP(6 chữ số) </label>
        < input
  type = "text"
  inputMode = "numeric"
  maxLength = { 6}
  value = { fpOtp }
  onChange = { e => setFpOtp(e.target.value.replace(/\D/g, '')) }
  placeholder = "______"
  className = "w-full h-12 px-4 rounded-xl border border-gray-200 bg-gray-50 text-gray-900 text-center text-xl tracking-[0.5em] font-bold focus:bg-white focus:ring-4 focus:ring-primary/10 focus:border-primary outline-none transition-all"
  autoFocus
    />
    </div>
    < div >
    <label className="block text-sm font-semibold text-gray-800 mb-2" > Mật khẩu mới </label>
      < input
  type = "password"
  value = { fpNewPass }
  onChange = { e => setFpNewPass(e.target.value) }
  placeholder = "Ít nhất 6 ký tự"
  className = "w-full h-12 px-4 rounded-xl border border-gray-200 bg-gray-50 text-gray-900 focus:bg-white focus:ring-4 focus:ring-primary/10 focus:border-primary outline-none transition-all"
    />
    </div>
    < div >
    <label className="block text-sm font-semibold text-gray-800 mb-2" > Xác nhận mật khẩu </label>
      < input
  type = "password"
  value = { fpConfirm }
  onChange = { e => setFpConfirm(e.target.value) }
  placeholder = "Nhập lại mật khẩu mới"
  className = "w-full h-12 px-4 rounded-xl border border-gray-200 bg-gray-50 text-gray-900 focus:bg-white focus:ring-4 focus:ring-primary/10 focus:border-primary outline-none transition-all"
    />
    </div>
    < div className = "flex gap-3" >
      <button
                  type="button"
  onClick = {() => { setFpStep(1); setFpError(''); }
}
className = "flex-1 h-12 rounded-xl border border-gray-300 font-semibold text-sm text-gray-600 hover:bg-gray-50 transition-colors"
  >
  Quay lai
    </button>
    < button
type = "submit"
disabled = { fpLoading }
className = "flex-[2] h-12 bg-primary hover:bg-orange-600 disabled:opacity-60 text-white font-semibold rounded-xl shadow-lg shadow-primary/20 transition-all flex items-center justify-center gap-2"
  >
{
  fpLoading
    ?<>< span className = "material-symbols-outlined animate-spin text-xl" > progress_activity < /span><span>Đang đặt lại...</span > </>
                    : 'Đặt lại mật khẩu'}
</button>
  </div>
  < p className = "text-center text-xs text-gray-400" >
    Không nhận được mã ? { ' '}
      < button type = "button" onClick = {() => { setFpStep(1); setFpError(''); setFpOtp(''); }} className = "text-primary font-semibold hover:underline" >
        Gửi lại
          </button>
          </p>
          </form>
          )}
</div>
  </div>
    );
  }

if (screen === Screen.LOGIN) {
  return (
    <div className= "flex min-h-screen w-full" >
    <div className="hidden md:flex w-1/2 bg-primary relative overflow-hidden" >
      <div className="absolute inset-0 bg-black/20 mix-blend-multiply" />
        <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80')] bg-cover bg-center opacity-60 mix-blend-overlay" />
          <div className="relative z-10 flex flex-col justify-between p-12 text-white h-full" >
            <div className="flex items-center gap-3" >
              <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center text-primary" >
                <span className="material-symbols-outlined" > restaurant </span>
                  </div>
                  < span className = "text-2xl font-bold" > ClickEat Merchant </span>
                    </div>
                    < div className = "max-w-md" >
                      <h1 className="text-5xl font-bold mb-4 leading-tight" > Nâng tầm gian bếp của bạn.</h1>
                        < p className = "text-lg font-medium opacity-90" > Quản lý đơn hàng, cập nhật thực đơn và theo dõi doanh thu — tất cả trong một.</p>
                          </div>
                          < p className = "text-sm opacity-70" >& copy; 2024 Hệ thống ClickEat.</p>
                            </div>
                            </div>
                            < div className = "flex-1 flex flex-col justify-center p-8 bg-white" >
                              <div className="max-w-md w-full mx-auto space-y-8" >
                                <div>
                                <h2 className="text-4xl font-bold text-gray-900 tracking-tight mb-2" > Đăng nhập </h2>
                                  < p className = "text-gray-500" > Chào mừng trở lại! Vui lòng nhập thông tin.</p>
                                    </div>
                                    < form className = "space-y-5" onSubmit = { handleLogin } >
                                      <div>
                                      <label className="block text-sm font-semibold text-gray-800 mb-2" > Email </label>
                                        < input
  type = "email"
  value = { email }
  onChange = { e => setEmail(e.target.value) }
  placeholder = "admin@clickeat.com"
  className = "w-full h-12 px-4 rounded-xl border border-gray-200 bg-gray-50 text-gray-900 focus:bg-white focus:ring-4 focus:ring-primary/10 focus:border-primary outline-none transition-all placeholder:text-gray-400"
    />
    </div>
    < div >
    <div className="flex justify-between mb-2" >
      <label className="block text-sm font-semibold text-gray-800" > Mật khẩu </label>
        < button type = "button" onClick = {() => onNavigate(Screen.FORGOT_PASSWORD)
} className = "text-sm text-primary font-semibold hover:underline" >
  Quên mật khẩu ?
    </button>
    </div>
    < input
                  type = "password"
value = { password }
onChange = { e => setPassword(e.target.value) }
placeholder = "..."
className = "w-full h-12 px-4 rounded-xl border border-gray-200 bg-gray-50 text-gray-900 focus:bg-white focus:ring-4 focus:ring-primary/10 focus:border-primary outline-none transition-all placeholder:text-gray-400"
  />
  </div>
{
  error && (
    <p className="text-red-500 text-sm font-medium flex items-center gap-1" >
      <span className="material-symbols-outlined text-sm" > error </span>
  { error }
  </p>
              )
}
<button
                type="submit"
disabled = { loading }
className = "w-full h-14 bg-primary hover:bg-orange-600 disabled:opacity-60 text-white font-semibold rounded-xl shadow-lg shadow-primary/20 transition-all text-lg flex items-center justify-center gap-2 group"
  >
{
  loading
    ?<>< span className = "material-symbols-outlined animate-spin text-xl" > progress_activity < /span><span>Đang đăng nhập...</span > </>
                  : <><span>Đăng nhập < /span><span className="material-symbols-outlined group-hover:translate-x-1 transition-transform">arrow_forward</span > </>}
</button>
  </form>
  < div className = "flex items-center gap-3" >
    <div className="flex-1 h-px bg-gray-200" />
      <span className="text-sm text-gray-400 font-medium" > hoặc </span>
        < div className = "flex-1 h-px bg-gray-200" />
          </div>
          < div ref = { googleBtnRef } className = "w-full flex justify-center min-h-[44px]" />
            <div className="text-center border-t border-gray-100 pt-6" >
              <p className="text-gray-500" >
                Mới dùng ClickEat ? { ' '}
                  < button onClick = {() => onNavigate(Screen.REGISTER_STEP_1)} className = "text-primary font-semibold hover:underline" >
                    Đăng ký cửa hàng
                      </button>
                      </p>
                      </div>
                      </div>
                      </div>
                      </div>
    );
  }

if (screen === Screen.REGISTER_SUCCESS) {
  return (
    <div className= "flex min-h-screen bg-white items-center justify-center p-4" >
    <div className="max-w-md w-full text-center space-y-6" >
      <div className="w-24 h-24 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6" >
        <span className="material-symbols-outlined text-5xl text-green-600" > check_circle </span>
          </div>
          < h2 className = "text-4xl font-bold text-gray-900" > Đã nhận hồ sơ! </h2>
            < p className = "text-gray-500 text-lg" > Cảm ơn bạn đã đăng ký.Đội ngũ chúng tôi sẽ xem xét hồ sơ trong vòng 24–48 giờ.</p>
              < div className = "pt-4" >
                <button onClick={ () => onNavigate(Screen.LOGIN) } className = "w-full h-14 bg-primary hover:bg-orange-600 text-white font-semibold rounded-xl shadow-lg shadow-primary/20 transition-all" >
                  Quay lại Đăng nhập
                    </button>
                    </div>
                    </div>
                    </div>
    );
}

return (
  <div className= "flex min-h-screen bg-gray-50" >
  <header className="fixed top-0 left-0 right-0 h-20 bg-white border-b border-gray-200 flex items-center justify-between px-8 z-50" >
    <div className="flex items-center gap-2 text-primary" >
      <span className="material-symbols-outlined text-3xl" > restaurant </span>
        < span className = "text-xl font-bold text-gray-900" > ClickEat </span>
          </div>
          < button onClick = {() => onNavigate(Screen.LOGIN)} className = "text-sm font-semibold text-gray-600 hover:text-gray-900" >
            Về trang đăng nhập
              </button>
              </header>
              < div className = "pt-20 w-full flex" >
                <div className="hidden lg:block w-80 fixed left-0 top-20 bottom-0 bg-white border-r border-gray-200 p-8 space-y-8" >
                  <div>
                  <h1 className="text-2xl font-bold mb-2" > Phát triển cùng ClickEat </h1>
                    < p className = "text-primary font-medium" > Trở thành đối tác ngay hôm nay </p>
                      </div>
                      < div className = "space-y-4" >
                      {
                        [
                          { id: Screen.REGISTER_STEP_1, label: 'Thông tin cơ bản', icon: 'person' },
                          { id: Screen.REGISTER_STEP_2, label: 'Chi tiết cửa hàng', icon: 'storefront' },
                          { id: Screen.REGISTER_STEP_3, label: 'Giấy tờ pháp lý', icon: 'description' },
            ].map((step, i) => (
                            <div key= { i } className = {`flex items-center gap-4 p-3 rounded-xl transition-all ${screen === step.id ? 'bg-primary/10 border border-primary/20' : 'text-gray-400'}`} >
                        <div className={ `w-8 h-8 rounded-lg flex items-center justify-center ${screen === step.id ? 'bg-primary text-white' : 'bg-gray-100 text-gray-400'}` }>
                          <span className="material-symbols-outlined text-sm" > { step.icon } </span>
                            </div>
                            < p className = {`text-sm font-semibold ${screen === step.id ? 'text-gray-900' : ''}`}> { step.label } </p>
                              </div>
            ))}
</div>
  </div>
  < div className = "flex-1 lg:ml-80 p-8 lg:p-16 flex justify-center" >
    <div className="w-full max-w-2xl bg-white p-8 rounded-2xl shadow-sm border border-gray-200 h-fit" >
      { screen === Screen.REGISTER_STEP_1 && (
        <div className="space-y-6" >
          <h2 className="text-3xl font-bold" > Thông tin cơ bản </h2>
{
  googleProfile && (
    <div className="flex items-center gap-3 bg-blue-50 border border-blue-200 rounded-xl px-4 py-3" >
      <span className="material-symbols-outlined text-blue-500" > account_circle </span>
        < div >
        <p className="text-sm font-semibold text-blue-800" > Đăng ký bằng tài khoản Google </p>
          < p className = "text-xs text-blue-600" > { googleProfile.email } </p>
            </div>
            </div>
          )
}
<div className = "grid grid-cols-2 gap-6" >
  <div className="col-span-2 md:col-span-1" >
    <label className="block text-sm font-semibold text-gray-800 mb-2" > Họ tên chủ cửa hàng </label>
      < input type = "text" value = { regName } onChange = { e => setRegName(e.target.value) } className = "w-full h-12 px-4 rounded-xl border border-gray-200 bg-gray-50 focus:bg-white focus:ring-4 focus:ring-primary/10 focus:border-primary outline-none transition-all" placeholder = "Nguyễn Văn A" />
        </div>
        < div className = "col-span-2 md:col-span-1" >
          <label className="block text-sm font-semibold text-gray-800 mb-2" > Tên nhà hàng </label>
            < input type = "text" className = "w-full h-12 px-4 rounded-xl border border-gray-200 bg-gray-50 focus:bg-white focus:ring-4 focus:ring-primary/10 focus:border-primary outline-none transition-all" placeholder = "Phở Ngon Gia Truyền" />
              </div>
{
  googleProfile ? (
    <div className= "col-span-2" >
    <label className="block text-sm font-semibold text-gray-800 mb-2" > Email(từ Google) </label>
      < input type = "email" readOnly value = { regEmail } className = "w-full h-12 px-4 rounded-xl border border-gray-200 bg-gray-100 text-gray-500 outline-none cursor-not-allowed" />
        </div>
                          ) : (
    <div className= "col-span-2" >
    <label className="block text-sm font-semibold text-gray-800 mb-2" > Email </label>
      < input type = "email" value = { regEmail } onChange = { e => setRegEmail(e.target.value) } className = "w-full h-12 px-4 rounded-xl border border-gray-200 bg-gray-50 focus:bg-white focus:ring-4 focus:ring-primary/10 focus:border-primary outline-none transition-all" placeholder = "email@example.com" />
        </div>
                          )
}
<div className = "col-span-2" >
  <label className="block text-sm font-semibold text-gray-800 mb-2" > Loại hình kinh doanh </label>
    < select className = "w-full h-12 px-4 rounded-xl border border-gray-200 bg-gray-50 focus:bg-white focus:ring-4 focus:ring-primary/10 focus:border-primary outline-none transition-all" >
      <option>Đồ ăn nhanh </option>
        < option > Nhà hàng </option>
          < option > Quán Cafe / Trà sữa </option>
            < option > Quán ăn vặt </option>
              </select>
              </div>
              </div>
              < button onClick = {() => onNavigate(Screen.REGISTER_STEP_2)} className = "w-full h-14 bg-primary text-white font-semibold rounded-xl hover:bg-orange-600 transition-colors" > Tiếp tục </button>
                </div>
            )}
{
  screen === Screen.REGISTER_STEP_2 && (
    <div className="space-y-6" >
      <h2 className="text-3xl font-bold" > Chi tiết cửa hàng </h2>
        < textarea className = "w-full rounded-xl border border-gray-200 bg-gray-50 p-4 min-h-[120px] focus:bg-white focus:ring-4 focus:ring-primary/10 focus:border-primary outline-none transition-all" placeholder = "Mô tả ngắn về cửa hàng của bạn..." />
          <div className="grid grid-cols-2 gap-4" >
            <div className="p-4 bg-gray-50 rounded-xl border border-gray-200 flex justify-between items-center" >
              <span className="font-semibold text-sm text-gray-800" > Thứ 2 – Thứ 6 </span>
                < span className = "text-sm bg-white px-2 py-1 rounded border" >09:00 - 22:00 </span>
                  </div>
                  </div>
                  < button onClick = {() => onNavigate(Screen.REGISTER_STEP_3)
} className = "w-full h-14 bg-primary text-white font-semibold rounded-xl hover:bg-orange-600 transition-colors" > Tiếp tục </button>
  </div>
            )}
{
  screen === Screen.REGISTER_STEP_3 && (
    <div className="space-y-6" >
      <h2 className="text-3xl font-bold" > Giấy tờ pháp lý </h2>
        < div className = "grid grid-cols-2 gap-6" >
        {
          ['Giấy phép kinh doanh', 'Chứng nhận ATVSTP', 'CCCD / Hộ chiếu', 'Thông tin ngân hàng'].map((doc, i) => (
            <div key= { i } className = "border-2 border-dashed border-gray-200 rounded-xl p-6 flex flex-col items-center justify-center bg-gray-50 hover:border-primary cursor-pointer transition-colors group" >
            <span className="material-symbols-outlined text-gray-400 group-hover:text-primary mb-2" > upload_file </span>
          < span className = "text-sm font-semibold text-gray-600" > { doc } </span>
          </div>
          ))
        }
          </div>
          < button onClick = {() => onNavigate(Screen.REGISTER_SUCCESS)
} className = "w-full h-14 bg-primary text-white font-semibold rounded-xl hover:bg-orange-600 transition-colors" > Gửi hồ sơ </button>
  </div>
            )}
</div>
  </div>
  </div>
  </div>
  );
};
