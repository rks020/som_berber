import { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useNavigate, useParams, useLocation } from 'react-router-dom';
import { Scissors, User, Phone, ChevronLeft, ChevronRight } from 'lucide-react';
import { supabase } from './lib/supabase';
import { format, addDays, startOfDay, isSameDay } from 'date-fns';
import { tr } from 'date-fns/locale';
import Admin from './Admin';
import LandingPage from './LandingPage';
import './App.css';

// Types
interface Barber {
  id: string;
  name: string;
  phone: string;
  profile_picture_path: string | null;
}

interface Service {
  id: string;
  name: string;
  price: number;
}

interface Appointment {
  id: string;
  date_time: string;
  duration_minutes: number;
  status: string;
}

// Components
const BookingHome = () => {
  const [barbers, setBarbers] = useState<Barber[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchPhone, setSearchPhone] = useState('');
  const [myAppointments, setMyAppointments] = useState<any[]>([]);
  const [searching, setSearching] = useState(false);

  useEffect(() => {
    const fetchBarbers = async () => {
      const { data } = await supabase.from('barbers').select('*');
      if (data) setBarbers(data);
      setLoading(false);
    };
    fetchBarbers();
  }, []);

  useEffect(() => {
    const channel = supabase.channel('customer-appointments')
      .on('postgres_changes' as any, { event: 'UPDATE', schema: 'public', table: 'appointments' }, (payload: any) => {
        setMyAppointments(prev => prev.map(app => 
          app.id === payload.new.id ? { ...app, status: payload.new.status, date_time: payload.new.date_time } : app
        ));
      })
      .on('postgres_changes' as any, { event: 'DELETE', schema: 'public', table: 'appointments' }, (payload: any) => {
        setMyAppointments(prev => prev.filter(app => app.id !== payload.old.id));
      })
      .subscribe();
      
    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const handleLookup = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!searchPhone) return;
    setSearching(true);
    try {
      // Normalize entered phone number (keep only digits)
      const digits = searchPhone.replace(/\D/g, '');
      
      // Generate common formats to check:
      // 1) Exactly as typed
      // 2) 10 digits (e.g. 5446253453)
      // 3) 11 digits with leading 0 (e.g. 05446253453)
      // 4) With country code 90 (e.g. 905446253453 or +905446253453)
      const formats = [searchPhone, digits];
      
      if (digits.length === 10) {
        formats.push('0' + digits);
        formats.push('90' + digits);
        formats.push('+90' + digits);
      } else if (digits.length === 11 && digits.startsWith('0')) {
        const tenDigit = digits.substring(1);
        formats.push(tenDigit);
        formats.push('90' + tenDigit);
        formats.push('+90' + tenDigit);
      } else if (digits.length > 10 && digits.startsWith('90')) {
        const tenDigit = digits.substring(2);
        formats.push(tenDigit);
        formats.push('0' + tenDigit);
        formats.push('+' + digits);
      }

      // Query customers database with any of these formats
      const { data: customerData } = await supabase
        .from('customers')
        .select('id')
        .in('phone', formats);
      
      if (!customerData || customerData.length === 0) {
        alert('Bu telefon numarasına ait aktif randevu kaydı bulunamadı. Lütfen numaranızı kontrol edin.');
        setMyAppointments([]);
        return;
      }

      const customerIds = customerData.map(c => c.id);

      // Fetch appointments
      const { data: appData, error } = await supabase
        .from('appointments')
        .select(`
          id,
          date_time,
          category,
          status,
          price,
          barber_id
        `)
        .in('customer_id', customerIds)
        .order('date_time', { ascending: false });

      if (!appData || appData.length === 0) {
        alert('Bu telefon numarasına ait aktif randevu kaydı bulunamadı.');
        setMyAppointments([]);
        return;
      }

      // Fetch barber names to display nicely
      const { data: bData } = await supabase.from('barbers').select('id, name');
      const barberMap = new Map(bData?.map(b => [b.id, b.name]) || []);
      
      const formatted = appData.map(app => ({
        ...app,
        barberName: barberMap.get(app.barber_id) || 'Bilinmiyor'
      }));
      setMyAppointments(formatted);
    } catch (err) {
      console.error(err);
    } finally {
      setSearching(false);
    }
  };

  const handleCancel = async (id: string) => {
    if (!confirm('Bu randevu talebini iptal etmek istediğinize emin misiniz? Bu işlem geri alınamaz.')) return;
    try {
      const { error } = await supabase
        .from('appointments')
        .update({ status: 'iptal' })
        .eq('id', id);
      
      if (error) throw error;
      alert('Randevu talebiniz iptal edildi.');
      // Refresh list locally
      setMyAppointments(prev => prev.map(app => app.id === id ? { ...app, status: 'iptal' } : app));
    } catch (err) {
      alert('İptal işlemi sırasında hata oluştu.');
      console.error(err);
    }
  };

  const handleAcceptSuggestion = async (id: string) => {
    try {
      const { error } = await supabase
        .from('appointments')
        .update({ status: 'onaylandı' })
        .eq('id', id);
      
      if (error) throw error;
      alert('Önerilen saat kabul edildi ve randevunuz onaylandı.');
      setMyAppointments(prev => prev.map(app => app.id === id ? { ...app, status: 'onaylandı' } : app));
    } catch (err) {
      alert('İşlem sırasında hata oluştu.');
      console.error(err);
    }
  };

  return (
    <div className="animate-fade-in">
      <div style={{ textAlign: 'center', marginBottom: '40px' }}>
        <h1 style={{ fontSize: '2rem', marginBottom: '12px', color: '#fff' }}>Randevu Al</h1>
        <p style={{ color: 'var(--text-muted)', fontSize: '1rem' }}>Randevu almak istediğiniz berberi seçin</p>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px' }}>Yükleniyor...</div>
      ) : (
        <>
          <div className="barber-grid">
            {barbers.map(barber => (
              <Link to={`/randevu/book/${barber.id}`} key={barber.id} className="glass-panel barber-card">
                <div className="barber-avatar">
                  {barber.profile_picture_path ? (
                    <img src={barber.profile_picture_path} alt={barber.name} />
                  ) : (
                    <User size={48} color="var(--text-muted)" />
                  )}
                </div>
                <div className="barber-info">
                  <h3>{barber.name}</h3>
                  <p>Randevu Al &rarr;</p>
                </div>
              </Link>
            ))}
          </div>

          {/* Appointment Lookup Section */}
          <div className="glass-panel" style={{ marginTop: '40px', padding: '24px' }}>
            <h3 style={{ color: '#fff', marginBottom: '12px' }}>🔎 Randevularımı Görüntüle / İptal Et</h3>
            <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', marginBottom: '20px' }}>
              Randevularınızı sorgulamak ve iptal etmek için sisteme kayıtlı telefon numaranızı girin.
            </p>
            <form onSubmit={handleLookup} style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
              <input 
                type="tel" 
                required 
                placeholder="Örn: 05XX XXX XX XX" 
                value={searchPhone} 
                onChange={e => setSearchPhone(e.target.value)} 
                style={{ flex: 1, minWidth: '200px' }}
              />
              <button type="submit" disabled={searching}>
                {searching ? 'Sorgulanıyor...' : 'Randevuları Bul'}
              </button>
            </form>

            {myAppointments.length > 0 && (
              <div style={{ marginTop: '24px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
                <h4 style={{ color: '#fff' }}>Randevularınız:</h4>
                {myAppointments.map(app => {
                  let statusText = app.status;
                  let statusColor = '#888888';
                  let showCancel = false;
                  let showAccept = false;

                  if (app.status === 'bekliyor') {
                    statusText = 'Onay Bekliyor';
                    statusColor = '#FFC107';
                    showCancel = true;
                  } else if (app.status === 'saat_onerildi') {
                    statusText = 'Yeni Saat Önerildi';
                    statusColor = '#FF9800';
                    showCancel = true; // behaves as Reject
                    showAccept = true;
                  } else if (app.status === 'onaylandı') {
                    statusText = 'Onaylandı';
                    statusColor = '#4CAF50';
                    showCancel = true;
                  } else if (app.status === 'iptal') {
                    statusText = 'İptal Ettiniz';
                    statusColor = '#F44336';
                  } else if (app.status === 'reddedildi') {
                    statusText = 'Reddedildi';
                    statusColor = '#F44336';
                  }

                  return (
                    <div key={app.id} className="appointment-item" style={{
                      display: 'flex', flexDirection: 'column',
                      padding: '16px', borderRadius: '12px', background: '#1E1E1E',
                      border: '1px solid rgba(255,255,255,0.06)', gap: '10px'
                    }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span style={{ fontWeight: 'bold', color: '#fff', fontSize: '15px' }}>{app.category}</span>
                        <span style={{
                          fontSize: '11px', padding: '4px 10px', borderRadius: '8px', fontWeight: 'bold',
                          background: `${statusColor}22`, color: statusColor
                        }}>
                          {statusText}
                        </span>
                      </div>
                      <div style={{ fontSize: '13px', color: '#ccc' }}>
                        Berber: <span style={{ color: '#fff', fontWeight: '500' }}>{app.barberName}</span>
                      </div>
                      <div style={{ fontSize: '13.5px', color: '#aaa' }}>
                        📅 {format(new Date(app.date_time), 'dd MMM yyyy HH:mm', { locale: tr })}
                      </div>

                      {(showCancel || showAccept) && (
                        <div style={{
                          display: 'flex', gap: '10px', justifyContent: 'flex-end',
                          borderTop: '1px solid rgba(255,255,255,0.05)', paddingTop: '10px', marginTop: '4px'
                        }}>
                          {showCancel && (
                            <button 
                              onClick={() => handleCancel(app.id)} 
                              style={{
                                background: 'transparent', color: '#F44336', border: '1px solid rgba(244,67,54,0.3)',
                                padding: '6px 12px', fontSize: '0.8rem', borderRadius: '6px', cursor: 'pointer'
                              }}
                            >
                              {app.status === 'saat_onerildi' ? 'Reddet / Talebi Sil' : 'İptal Et'}
                            </button>
                          )}
                          {showAccept && (
                            <button 
                              onClick={() => handleAcceptSuggestion(app.id)} 
                              style={{
                                background: '#4CAF50', color: '#fff', border: 'none',
                                padding: '6px 14px', fontSize: '0.8rem', borderRadius: '6px', cursor: 'pointer', fontWeight: 'bold'
                              }}
                            >
                              Kabul Et
                            </button>
                          )}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
};

const Booking = () => {
  const { barberId } = useParams<{ barberId: string }>();
  const navigate = useNavigate();
  const [barber, setBarber] = useState<Barber | null>(null);
  const [services, setServices] = useState<Service[]>([]);
  const [selectedDate, setSelectedDate] = useState<Date>(startOfDay(new Date()));
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  
  const [selectedServices, setSelectedServices] = useState<string[]>([]);
  const [selectedTime, setSelectedTime] = useState<string>('');
  const [customerName, setCustomerName] = useState('');
  const [customerPhone, setCustomerPhone] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    const loadData = async () => {
      if (!barberId) return;
      
      const { data: bData } = await supabase.from('barbers').select('*').eq('id', barberId).single();
      if (bData) setBarber(bData);

      const { data: sData } = await supabase.from('services').select('*');
      if (sData) setServices(sData);
    };
    loadData();
  }, [barberId]);

  useEffect(() => {
    const fetchAppointments = async () => {
      if (!barberId) return;
      const start = selectedDate.toISOString();
      const end = addDays(selectedDate, 1).toISOString();
      
      const { data } = await supabase
        .from('appointments')
        .select('*')
        .eq('barber_id', barberId)
        .gte('date_time', start)
        .lt('date_time', end);
        
      if (data) setAppointments(data);
    };
    fetchAppointments();
  }, [barberId, selectedDate]);

  const isSunday = (date: Date) => date.getDay() === 0;

  const navigateDate = (direction: number) => {
    let next = addDays(selectedDate, direction);
    if (isSunday(next)) next = addDays(next, direction); // skip Sunday
    if (next < startOfDay(new Date())) return;
    setSelectedDate(next);
    setSelectedTime('');
  };

  const handleServiceToggle = (serviceId: string) => {
    setSelectedServices(prev => 
      prev.includes(serviceId)
        ? prev.filter(id => id !== serviceId)
        : [...prev, serviceId]
    );
  };

  // Generate 30-min time slots from 08:00 to 22:00
  const generateTimeSlots = () => {
    const slots = [];
    let currentHour = 8;
    let currentMinute = 0;
    
    while (currentHour < 22) {
      const timeString = `${currentHour.toString().padStart(2, '0')}:${currentMinute.toString().padStart(2, '0')}`;
      slots.push(timeString);
      
      currentMinute += 30;
      if (currentMinute >= 60) {
        currentHour += 1;
        currentMinute = 0;
      }
    }
    return slots;
  };

  const isSlotDisabled = (time: string) => {
    const [hours, minutes] = time.split(':').map(Number);
    const slotTime = new Date(selectedDate);
    slotTime.setHours(hours, minutes, 0, 0);

    if (isSameDay(slotTime, new Date()) && slotTime.getTime() < new Date().getTime()) {
      return true; // Past time
    }

    // Check overlaps
    return appointments.some(app => {
      const appStart = new Date(app.date_time).getTime();
      const appEnd = appStart + (app.duration_minutes * 60000);
      const slotStart = slotTime.getTime();
      const slotEnd = slotStart + (30 * 60000); // assume 30min default
      
      return (slotStart < appEnd && slotEnd > appStart);
    });
  };

  const handleBook = async (e: React.FormEvent) => {
    e.preventDefault();
    if (selectedServices.length === 0 || !selectedTime || !customerName || !customerPhone || !barberId) return;
    
    setSubmitting(true);
    try {
      const selectedList = services.filter(s => selectedServices.includes(s.id));
      const combinedCategoryName = selectedList.map(s => s.name).join(', ');
      const totalCombinedPrice = selectedList.reduce((acc, curr) => acc + curr.price, 0);
      
      // Check if customer exists
      const digits = customerPhone.replace(/\D/g, '');
      const formats = [customerPhone, digits];
      if (digits.length === 10) {
        formats.push('0' + digits);
        formats.push('90' + digits);
        formats.push('+90' + digits);
      } else if (digits.length === 11 && digits.startsWith('0')) {
        const tenDigit = digits.substring(1);
        formats.push(tenDigit);
        formats.push('90' + tenDigit);
        formats.push('+90' + tenDigit);
      } else if (digits.length > 10 && digits.startsWith('90')) {
        const tenDigit = digits.substring(2);
        formats.push(tenDigit);
        formats.push('0' + tenDigit);
        formats.push('+' + digits);
      }

      const { data: existingCustomers } = await supabase
        .from('customers')
        .select('id')
        .in('phone', formats);

      let customerId;
      if (existingCustomers && existingCustomers.length > 0) {
        customerId = existingCustomers[0].id;
      } else {
        customerId = crypto.randomUUID();
        await supabase.from('customers').insert({
          id: customerId,
          name: customerName,
          phone: customerPhone
        });
      }

      const [hours, minutes] = selectedTime.split(':').map(Number);
      const appTime = new Date(selectedDate);
      appTime.setHours(hours, minutes, 0, 0);

      const appointmentId = crypto.randomUUID();
      await supabase.from('appointments').insert({
        id: appointmentId,
        title: customerName,
        category: combinedCategoryName || 'Randevu',
        date_time: appTime.toISOString(),
        duration_minutes: 30, // Default duration
        price: totalCombinedPrice,
        color_hex: '#4CAF50', // Default green
        status: 'bekliyor', // pending approval
        customer_id: customerId,
        barber_id: barberId
      });

      alert('Randevu talebiniz başarıyla alındı!');
      navigate('/randevu');
    } catch (error) {
      alert('Bir hata oluştu. Lütfen tekrar deneyin.');
      console.error(error);
    } finally {
      setSubmitting(false);
    }
  };

  if (!barber) return <div style={{ textAlign: 'center', padding: '40px' }}>Yükleniyor...</div>;

  return (
    <div className="animate-fade-in glass-panel">
      <button onClick={() => navigate('/')} style={{ marginBottom: '24px', background: 'transparent', color: 'var(--primary-color)', border: '1px solid var(--primary-color)' }}>
        &larr; Geri
      </button>
      
      <div style={{ display: 'flex', alignItems: 'center', gap: '20px', marginBottom: '32px' }}>
        <div className="barber-avatar" style={{ width: '80px', height: '80px' }}>
          {barber.profile_picture_path ? (
            <img src={barber.profile_picture_path} alt={barber.name} />
          ) : (
            <User size={32} color="var(--text-muted)" />
          )}
        </div>
        <div>
          <h2>{barber.name}</h2>
          <p style={{ color: 'var(--text-muted)' }}>Randevu Talebi Oluştur</p>
        </div>
      </div>

      <div className="booking-container">
        <div>
          <div className="date-selector">
            <button className="date-btn" onClick={() => navigateDate(-1)} disabled={isSameDay(selectedDate, new Date())}>
              <ChevronLeft size={20} />
            </button>
            <h3 style={{ margin: 0, minWidth: '160px', textAlign: 'center', color: '#fff' }}>
              {format(selectedDate, 'd MMMM yyyy', { locale: tr })}
              {isSunday(selectedDate) && (
                <span style={{ display: 'block', fontSize: '11px', color: '#ef4444', letterSpacing: '1px', textTransform: 'uppercase', marginTop: '4px' }}>Pazar – Kapalı</span>
              )}
            </h3>
            <button className="date-btn" onClick={() => navigateDate(1)}>
              <ChevronRight size={20} />
            </button>
          </div>

          {isSunday(selectedDate) ? (
            <div style={{
              display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
              gap: '12px', padding: '40px 16px', textAlign: 'center',
              background: 'rgba(239,68,68,0.07)', borderRadius: '12px',
              border: '1px solid rgba(239,68,68,0.2)', marginTop: '16px'
            }}>
              <div style={{ fontSize: '40px' }}>🚫</div>
              <div style={{ color: '#ef4444', fontWeight: '700', fontSize: '16px' }}>Pazar Günleri Kapalıyız</div>
              <div style={{ color: 'var(--text-muted)', fontSize: '13px', maxWidth: '260px', lineHeight: '1.6' }}>
                Salonumuz her Pazar günü kapalıdır.<br />
                Lütfen başka bir gün seçin.
              </div>
              <div style={{ display: 'flex', gap: '10px', marginTop: '8px' }}>
                <button className="date-btn" style={{ padding: '8px 16px', fontSize: '13px' }} onClick={() => navigateDate(-1)}>← Önceki Gün</button>
                <button className="date-btn" style={{ padding: '8px 16px', fontSize: '13px' }} onClick={() => navigateDate(1)}>Sonraki Gün →</button>
              </div>
            </div>
          ) : (
            <div className="time-slots">
              {generateTimeSlots().map(time => {
                const disabled = isSlotDisabled(time);
                return (
                  <div
                    key={time}
                    className={`time-slot ${disabled ? 'disabled' : ''} ${selectedTime === time ? 'selected' : ''}`}
                    onClick={() => !disabled && setSelectedTime(time)}
                  >
                    {time}
                  </div>
                );
              })}
            </div>
          )}
        </div>

        <div>
          <form onSubmit={handleBook}>
            <div className="form-group">
              <label><User size={16} style={{ verticalAlign: 'middle', marginRight: '8px' }} />Ad Soyad</label>
              <input type="text" required value={customerName} onChange={e => setCustomerName(e.target.value)} placeholder="Örn: Ali Yılmaz" />
            </div>
            
             <div className="form-group">
              <label><Phone size={16} style={{ verticalAlign: 'middle', marginRight: '8px' }} />Telefon Numarası</label>
              <input type="tel" required value={customerPhone} onChange={e => setCustomerPhone(e.target.value)} placeholder="05XX XXX XX XX" />
              <p style={{ color: '#FFC107', fontSize: '0.8rem', marginTop: '6px', lineHeight: '1.4' }}>
                ⚠️ Lütfen telefon numaranızı doğru giriniz. Randevunuzu teyit etmek için sizi bu numaradan arayacağız.
              </p>
            </div>

            <div className="form-group">
              <label><Scissors size={16} style={{ verticalAlign: 'middle', marginRight: '8px' }} />Hizmet Seçimi (Birden fazla seçebilirsiniz)</label>
              <div style={{
                display: 'flex', flexDirection: 'column', gap: '10px',
                maxHeight: '200px', overflowY: 'auto', padding: '12px',
                background: 'rgba(255,255,255,0.02)', border: '1px solid rgba(255,255,255,0.08)',
                borderRadius: '8px', marginTop: '6px'
              }}>
                {services.map(s => (
                  <label key={s.id} style={{ display: 'flex', alignItems: 'center', gap: '10px', cursor: 'pointer', fontSize: '14.5px', color: '#fff' }}>
                    <input 
                      type="checkbox" 
                      checked={selectedServices.includes(s.id)}
                      onChange={() => handleServiceToggle(s.id)}
                      style={{ width: '18px', height: '18px', cursor: 'pointer', accentColor: 'var(--primary-color)' }}
                    />
                    <span>{s.name} - <strong>{s.price} ₺</strong></span>
                  </label>
                ))}
              </div>
            </div>

            <button type="submit" disabled={submitting || !selectedTime || selectedServices.length === 0 || isSunday(selectedDate)} style={{ width: '100%', marginTop: '16px', padding: '16px' }}>
              {submitting ? 'Gönderiliyor...' : 'Randevu Talebini Gönder'}
            </button>
            {isSunday(selectedDate) && <p style={{ color: '#ef4444', fontSize: '0.9rem', textAlign: 'center', marginTop: '12px' }}>🚫 Pazar günleri randevu alınamaz</p>}
            {!isSunday(selectedDate) && !selectedTime && <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', textAlign: 'center', marginTop: '12px' }}>Lütfen sol taraftan bir saat seçin</p>}
          </form>
        </div>
      </div>
    </div>
  );
};

const AppContent = () => {
  const location = useLocation();
  const isAdmin = location.pathname.startsWith('/admin');
  const isLanding = location.pathname === '/';
  const isBooking = location.pathname.startsWith('/randevu');

  return (
    <div className="app-container">
      {isBooking && (
        <header>
          <Link to="/" className="logo" style={{ textDecoration: 'none', color: 'inherit' }}>
            <img src="/logo.png" alt="Logo" style={{ width: '40px', height: '40px', borderRadius: '8px' }} />
            SO Yılmaz Berber
          </Link>
          <Link to="/" style={{ color: 'var(--text-muted)', fontSize: '13px', textDecoration: 'none' }}>← Ana Sayfaya Dön</Link>
        </header>
      )}
      <main style={{ padding: (isAdmin || isLanding) ? 0 : undefined }}>
        <Routes>
          <Route path="/" element={<LandingPage />} />
          <Route path="/randevu" element={<div className="container"><BookingHome /></div>} />
          <Route path="/randevu/book/:barberId" element={<div className="container"><Booking /></div>} />
          <Route path="/admin/*" element={<Admin />} />
        </Routes>
      </main>
    </div>
  );
};

function App() {
  return (
    <Router>
      <AppContent />
    </Router>
  );
}

export default App;
