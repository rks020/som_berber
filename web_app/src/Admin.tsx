import { useState, useEffect } from 'react';
import { Routes, Route, Link, useNavigate, useLocation } from 'react-router-dom';
import { supabase } from './lib/supabase';
import { LayoutDashboard, Users, Scissors, CalendarCheck, LogOut, Check, X, Trash2, Wallet, Clock, Phone, MessageCircle } from 'lucide-react';
import { format, parseISO } from 'date-fns';
import { tr } from 'date-fns/locale';

// Types (reusing or extending)
interface Customer {
  id: string;
  name: string;
  phone: string;
}

interface Barber {
  id: string;
  name: string;
}

interface Service {
  id: string;
  name: string;
  price: number;
}

interface Appointment {
  id: string;
  title: string;
  category: string;
  date_time: string;
  status: string;
  customer_id: string;
  barber_id: string;
  duration_minutes: number;
  color_hex: string;
  price: number;
  additional_people?: string;
}

const AdminLogin = ({ onLogin }: { onLogin: () => void }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    
    // Check custom admins table
    const { data } = await supabase
      .from('admins')
      .select('*')
      .eq('email', email)
      .eq('password', password)
      .single();

    if (data) {
      localStorage.setItem('adminAuth', 'true');
      onLogin();
    } else {
      setError('E-posta veya şifre hatalı!');
    }
  };

  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '80vh' }}>
      <div className="glass-panel" style={{ width: '400px', padding: '40px' }}>
        <h2 style={{ textAlign: 'center', marginBottom: '24px' }}>Yönetici Girişi</h2>
        <form onSubmit={handleLogin}>
          <div className="form-group">
            <label>E-posta</label>
            <input type="email" required value={email} onChange={e => setEmail(e.target.value)} />
          </div>
          <div className="form-group">
            <label>Şifre</label>
            <input type="password" required value={password} onChange={e => setPassword(e.target.value)} />
          </div>
          {error && <p style={{ color: '#ff4444', marginBottom: '16px' }}>{error}</p>}
          <button type="submit" style={{ width: '100%' }}>Giriş Yap</button>
        </form>
      </div>
    </div>
  );
};

const Sidebar = ({ onLogout, unreadCount }: { onLogout: () => void, unreadCount: number }) => {
  const location = useLocation();
  const menu = [
    { name: 'Randevular', path: '/admin', icon: <CalendarCheck size={20} /> },
    { name: 'Talepler', path: '/admin/requests', icon: <Clock size={20} /> },
    { name: 'Müşteriler', path: '/admin/customers', icon: <Users size={20} /> },
    { name: 'Hizmetler', path: '/admin/services', icon: <Scissors size={20} /> },
    { name: 'Adisyonlar', path: '/admin/visits', icon: <LayoutDashboard size={20} /> },
    { name: 'Finans', path: '/admin/finance', icon: <Wallet size={20} /> },
  ];

  return (
    <div style={{ width: '250px', borderRight: '1px solid rgba(255,255,255,0.1)', padding: '24px', display: 'flex', flexDirection: 'column' }}>
      <h2 style={{ color: 'var(--primary-color)', marginBottom: '32px' }}>SOM Admin</h2>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '8px' }}>
        {menu.map(item => {
          const isRequests = item.path === '/admin/requests';
          const isActive = location.pathname === item.path || (location.pathname === '/admin/' && item.path === '/admin');
          return (
            <Link 
              key={item.path} 
              to={item.path} 
              style={{ 
                display: 'flex', alignItems: 'center', gap: '12px', padding: '12px', 
                borderRadius: '8px', 
                backgroundColor: isActive ? 'var(--primary-color)' : 'transparent',
                color: isActive ? '#000' : 'var(--text-color)',
                fontWeight: isActive ? 600 : 400,
                textDecoration: 'none'
              }}
            >
              {item.icon}
              <span>{item.name}</span>
              {isRequests && unreadCount > 0 && (
                <span style={{
                  backgroundColor: '#ff4444',
                  color: 'white',
                  borderRadius: '10px',
                  padding: '2px 8px',
                  fontSize: '0.75rem',
                  fontWeight: 'bold',
                  marginLeft: 'auto'
                }}>
                  {unreadCount}
                </span>
              )}
            </Link>
          );
        })}
      </div>
      <button onClick={onLogout} style={{ background: 'transparent', color: '#ff4444', border: '1px solid #ff4444', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
        <LogOut size={18} /> Çıkış Yap
      </button>
    </div>
  );
};

import { startOfWeek, addDays } from 'date-fns';

let sharedAudioCtx: AudioContext | null = null;
const initAudio = () => {
  if (!sharedAudioCtx) {
    const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
    if (AudioContextClass) sharedAudioCtx = new AudioContextClass();
  }
  if (sharedAudioCtx && sharedAudioCtx.state === 'suspended') {
    sharedAudioCtx.resume();
  }
};
// Resume audio context on any click to bypass autoplay policies
if (typeof document !== 'undefined') {
  document.addEventListener('click', initAudio, { once: true });
}

const AppointmentsManager = () => {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [barbers, setBarbers] = useState<Barber[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [services, setServices] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedBarberId, setSelectedBarberId] = useState<string | null>(null);

  // Week navigation
  const [currentDate, setCurrentDate] = useState(new Date());

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingAppointmentId, setEditingAppointmentId] = useState<string | null>(null);
  const [selectedSlot, setSelectedSlot] = useState<{date: Date, hour: number} | null>(null);
  
  // Custom Delete Confirm State
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
  
  // Form fields
  const [newTitle, setNewTitle] = useState('');
  const [newApptServices, setNewApptServices] = useState<string[]>([]);
  const [newDate, setNewDate] = useState('');
  const [newTime, setNewTime] = useState('');
  const [newDuration, setNewDuration] = useState(60);
  const [newPrice, setNewPrice] = useState<number | ''>('');
  const [newOthers, setNewOthers] = useState('');
  const [newColor, setNewColor] = useState('#ff9800');
  const [isCategoryDropdownOpen, setIsCategoryDropdownOpen] = useState(false);
  
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [pendingRequest, setPendingRequest] = useState<Appointment | null>(null);
  const [isSuggestingNewTime, setIsSuggestingNewTime] = useState(false);
  const [suggestedDateTime, setSuggestedDateTime] = useState('');

  const handleSuggestNewTime = async () => {
    if (!pendingRequest || !suggestedDateTime) return;
    const isoDateTime = new Date(suggestedDateTime).toISOString();
    await supabase.from('appointments').update({
      date_time: isoDateTime,
      status: 'saat_onerildi'
    }).eq('id', pendingRequest.id);
    setPendingRequest(null);
    setIsSuggestingNewTime(false);
    fetchData();
  };

  const handleApprovePending = async () => {
    if (!pendingRequest) return;
    await supabase.from('appointments').update({ status: 'onaylandı' }).eq('id', pendingRequest.id);
    setPendingRequest(null);
    fetchData();
  };

  const handleRejectPending = async () => {
    if (!pendingRequest) return;
    await supabase.from('appointments').delete().eq('id', pendingRequest.id);
    setPendingRequest(null);
    fetchData();
  };

  useEffect(() => {
    fetchData();

    // Realtime: update when mobile adds appointments
    const channel = supabase
      .channel('web:appointments')
      .on('postgres_changes' as any, { event: 'INSERT', schema: 'public', table: 'appointments' }, (payload: any) => {
        fetchData();
        const newApp = payload.new;
        if (newApp && newApp.status === 'bekliyor') {
          // Play notification sound
          new Audio('https://assets.mixkit.co/active_storage/sfx/2869/2869-500.wav').play().catch(() => {});
          setPendingRequest(newApp);
        }
      })
      .on('postgres_changes' as any, { event: 'UPDATE', schema: 'public', table: 'appointments' }, () => {
        fetchData();
      })
      .on('postgres_changes' as any, { event: 'DELETE', schema: 'public', table: 'appointments' }, () => {
        fetchData();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (barbers.length > 0 && !selectedBarberId) {
      setSelectedBarberId(barbers[0].id);
    }
  }, [barbers, selectedBarberId]);

  const fetchData = async () => {
    setLoading(true);
    const { data: bData } = await supabase.from('barbers').select('*');
    if (bData) setBarbers(bData);

    const { data: cData } = await supabase.from('customers').select('*');
    if (cData) setCustomers(cData);

    const { data: sData } = await supabase.from('services').select('*');
    if (sData) setServices(sData);

    const { data: aData } = await supabase.from('appointments').select('*').order('date_time', { ascending: false });
    if (aData) setAppointments(aData);
    setLoading(false);
  };

  const handleCreateAppointment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedBarberId || !newTitle || newApptServices.length === 0 || !newDate || !newTime) return;
    
    setIsSubmitting(true);
    const serviceNames = newApptServices.map(id => services.find(s => s.id === id)?.name).filter(Boolean).join(', ');
    const dt = new Date(`${newDate}T${newTime}`);

    const matchedCustomer = customers.find(c => c.name.toLowerCase() === newTitle.toLowerCase());

    const payload = {
      title: newTitle,
      category: serviceNames || '',
      date_time: dt.toISOString(),
      status: 'onaylandı',
      customer_id: matchedCustomer ? matchedCustomer.id : null,
      barber_id: selectedBarberId,
      duration_minutes: newDuration,
      price: Number(newPrice) || 0,
      additional_people: newOthers,
      color_hex: newColor
    };

    if (editingAppointmentId) {
      await supabase.from('appointments').update(payload).eq('id', editingAppointmentId);
    } else {
      const id = crypto.randomUUID();
      await supabase.from('appointments').insert({ id, ...payload });
    }

    setIsModalOpen(false);
    setEditingAppointmentId(null);
    await fetchData();
    setIsSubmitting(false);
  };

  const handleUpdateStatus = async (id: string, status: string) => {
    await supabase.from('appointments').update({ status }).eq('id', id);
    fetchData();
  };

  const handleDelete = async (id: string) => {
    setDeleteConfirmId(id);
  };

  const confirmDelete = async () => {
    if (deleteConfirmId) {
      await supabase.from('appointments').delete().eq('id', deleteConfirmId);
      setDeleteConfirmId(null);
      setIsModalOpen(false);
      setEditingAppointmentId(null);
      fetchData();
    }
  };

  // Build calendar data
  const weekStart = startOfWeek(currentDate, { weekStartsOn: 1 }); // Monday
  const days = Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));
  const hours = Array.from({ length: 15 }, (_, i) => i + 8); // 8 to 22

  const filteredAppointments = appointments.filter(a => a.barber_id === selectedBarberId && a.status !== 'iptal' && a.status !== 'reddedildi');



  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '12px' }}>
        <div>
          <h2 style={{ margin: 0 }}>Randevu Listesi</h2>
          <p style={{ color: 'var(--text-muted)', margin: '4px 0 0 0', fontSize: '0.9rem' }}>Berber bazlı haftalık taslak ve randevu yönetimi.</p>
        </div>
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <button onClick={() => setCurrentDate(addDays(currentDate, -7))} style={{ background: 'var(--primary-color)', color: '#000', padding: '6px 12px' }}>&lt;</button>
          <span style={{ fontWeight: 'bold' }}>{format(weekStart, 'd MMM', { locale: tr })} - {format(addDays(weekStart, 6), 'd MMM yyyy', { locale: tr })}</span>
          <button onClick={() => setCurrentDate(addDays(currentDate, 7))} style={{ background: 'var(--primary-color)', color: '#000', padding: '6px 12px' }}>&gt;</button>
        </div>
      </div>
      
      {/* Barber Tabs */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '16px', overflowX: 'auto', paddingBottom: '4px' }}>
        {barbers.map(barber => (
          <button 
            key={barber.id}
            onClick={() => setSelectedBarberId(barber.id)}
            style={{
              background: selectedBarberId === barber.id ? 'var(--primary-color)' : 'transparent',
              color: selectedBarberId === barber.id ? '#000' : 'var(--primary-color)',
              fontWeight: 'bold',
              border: selectedBarberId === barber.id ? 'none' : '1px solid rgba(255,255,255,0.1)',
              padding: '8px 16px',
              fontSize: '0.85rem',
              borderRadius: '8px',
              cursor: 'pointer',
              whiteSpace: 'nowrap'
            }}
          >
            {barber.name.toUpperCase()}
          </button>
        ))}
      </div>

      {loading ? <p>Yükleniyor...</p> : (
        <div className="glass-panel" style={{ padding: '0', overflowX: 'auto' }}>
          <div style={{ minWidth: '800px', display: 'grid', gridTemplateColumns: '50px repeat(7, 1fr)', borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
            {/* Header */}
            <div style={{ padding: '4px', borderRight: '1px solid rgba(255,255,255,0.05)' }}></div>
            {days.map((day, i) => {
              const isSunday = day.getDay() === 0;
              return (
                <div key={i} style={{ padding: '4px', textAlign: 'center', fontWeight: 'bold', color: isSunday ? '#f44336' : 'var(--primary-color)', borderRight: '1px solid rgba(255,255,255,0.05)' }}>
                  <span style={{ fontSize: '0.75rem' }}>{format(day, 'EEE', { locale: tr })} {isSunday && '🔒'}</span><br/>
                  <span style={{ fontSize: '0.65rem', color: isSunday ? '#f44336' : 'var(--text-muted)' }}>{format(day, 'd MMM', { locale: tr })}</span>
                </div>
              );
            })}
          </div>

          <div style={{ minWidth: '800px', display: 'flex' }}>
            {/* Hours column */}
            <div style={{ width: '50px', borderRight: '1px solid rgba(255,255,255,0.05)' }}>
              {hours.map(hour => (
                <div key={hour} style={{ height: '36px', boxSizing: 'border-box', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', alignItems: 'flex-start', justifyContent: 'center', paddingTop: '4px', fontSize: '0.7rem', color: 'var(--text-muted)' }}>
                  {hour.toString().padStart(2, '0')}:00
                </div>
              ))}
            </div>
            
            {/* Days columns */}
            {days.map((day, dIdx) => {
              const isSunday = day.getDay() === 0;
              const dayApps = filteredAppointments.filter(app => {
                const appDate = parseISO(app.date_time);
                return appDate.getDate() === day.getDate() && 
                       appDate.getMonth() === day.getMonth() && 
                       appDate.getFullYear() === day.getFullYear();
              });

              return (
                <div key={dIdx} style={{ flex: 1, position: 'relative', borderRight: '1px solid rgba(255,255,255,0.05)' }}>
                  {/* Grid cells for clicking */}
                  {hours.map(hour => {
                    if (isSunday) {
                      return (
                        <div 
                          key={hour}
                          style={{ 
                            height: '36px', 
                            boxSizing: 'border-box', 
                            borderBottom: '1px solid rgba(255,255,255,0.05)', 
                            background: 'rgba(244, 67, 54, 0.06)',
                            color: '#ff4444',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontSize: '0.75rem',
                            fontWeight: 'bold',
                            cursor: 'not-allowed',
                            userSelect: 'none'
                          }}
                        >
                          KAPALI
                        </div>
                      );
                    }
                    return (
                      <div 
                        key={hour}
                        onClick={() => {
                          setSelectedSlot({ date: day, hour });
                          setEditingAppointmentId(null);
                          setNewDate(format(day, 'yyyy-MM-dd'));
                          setNewTime(hour.toString().padStart(2, '0') + ':00');
                          setNewTitle('');
                          setNewApptServices([]);
                          setNewDuration(60);
                          setNewPrice('');
                          setNewOthers('');
                          setNewColor('#ff9800');
                          setIsCategoryDropdownOpen(false);
                          setIsModalOpen(true); 
                        }}
                        style={{ height: '36px', boxSizing: 'border-box', borderBottom: '1px solid rgba(255,255,255,0.05)', cursor: 'pointer' }}
                      />
                    );
                  })}
                  
                  {/* Appointments overlaid */}
                  {dayApps.map(app => {
                    const appDate = parseISO(app.date_time);
                    const minutesFromStart = (appDate.getHours() - 8) * 60 + appDate.getMinutes();
                    const top = (minutesFromStart / 60) * 36;
                    const duration = app.duration_minutes || 60;
                    const height = (duration / 60) * 36;

                    return (
                      <div 
                        key={app.id} 
                        onClick={(e) => {
                          e.stopPropagation();
                          setSelectedSlot({ date: appDate, hour: appDate.getHours() });
                          setEditingAppointmentId(app.id);
                          setNewTitle(app.title);
                          setNewDate(format(appDate, 'yyyy-MM-dd'));
                          setNewTime(format(appDate, 'HH:mm'));
                          setNewDuration(app.duration_minutes || 60);
                          setNewPrice(app.price || '');
                          setNewOthers(app.additional_people || '');
                          setNewColor(app.color_hex || '#ff9800');
                          
                          // match services by name (approximate, since we stored a comma separated string)
                          const matchedServiceIds = services
                            .filter(s => (app.category || '').includes(s.name))
                            .map(s => s.id);
                          setNewApptServices(matchedServiceIds);
                          
                          setIsCategoryDropdownOpen(false);
                          setIsModalOpen(true);
                        }}
                        title={`${app.title} - ${app.category}`}
                        style={{ 
                          position: 'absolute',
                          top: `${top + 1}px`,
                          height: `${Math.max(16, height - 2)}px`,
                          left: '4px',
                          right: '4px',
                          background: app.color_hex || (app.status === 'bekliyor' ? '#ff9800' : 'var(--primary-color)'), 
                          color: '#000', 
                          padding: '2px 4px', 
                          borderRadius: '4px', 
                          display: 'flex',
                          flexDirection: 'column',
                          boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
                          zIndex: 5,
                          overflow: 'hidden'
                        }}
                      >
                        <div style={{ fontWeight: 'bold', fontSize: '0.55rem', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                          {app.title} - {app.category}
                        </div>
                        <div style={{ display: 'flex', gap: '4px', justifyContent: 'flex-end', marginTop: 'auto' }}>
                          {app.status === 'bekliyor' && (
                            <button onClick={(e) => { e.stopPropagation(); handleUpdateStatus(app.id, 'onaylandı'); }} style={{ background: 'rgba(0,0,0,0.1)', padding: '2px', color: '#000', border: 'none', borderRadius: '4px' }}>
                              <Check size={10} />
                            </button>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              );
            })}
          </div>
        </div>
      )}

      {isModalOpen && selectedSlot && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.8)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="glass-panel" style={{ width: '400px', maxHeight: '90vh', overflowY: 'auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
              <h3 style={{ margin: 0 }}>{editingAppointmentId ? 'Randevuyu Düzenle' : 'Yeni Randevu'}</h3>
              <button onClick={() => { setIsModalOpen(false); setEditingAppointmentId(null); }} style={{ background: 'transparent', padding: 0, color: 'var(--text-light)', border: 'none', cursor: 'pointer' }}><X size={24} /></button>
            </div>

            <form onSubmit={handleCreateAppointment}>
              <div className="form-group" style={{ marginBottom: '16px', position: 'relative' }}>
                <label style={{ display: 'block', marginBottom: '8px' }}>Kategori (Çoklu Seçim)</label>
                <div 
                  onClick={() => setIsCategoryDropdownOpen(!isCategoryDropdownOpen)}
                  style={{ 
                    padding: '12px', 
                    background: 'rgba(255, 255, 255, 0.05)', 
                    border: '1px solid rgba(255,255,255,0.1)', 
                    borderRadius: '8px', 
                    cursor: 'pointer',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    minHeight: '48px'
                  }}>
                  <span style={{ opacity: newApptServices.length > 0 ? 1 : 0.5 }}>
                    {newApptServices.length > 0 
                      ? newApptServices.map(id => services.find(s => s.id === id)?.name).filter(Boolean).join(', ') 
                      : 'Kategori Seçin'}
                  </span>
                  <span>▼</span>
                </div>
                
                {isCategoryDropdownOpen && (
                  <div style={{ 
                    position: 'absolute', 
                    top: '100%', 
                    left: 0, 
                    right: 0, 
                    background: 'var(--surface-color)', 
                    border: '1px solid rgba(255,255,255,0.1)', 
                    borderRadius: '8px', 
                    marginTop: '4px',
                    maxHeight: '200px', 
                    overflowY: 'auto',
                    zIndex: 10,
                    boxShadow: '0 10px 25px rgba(0,0,0,0.5)'
                  }}>
                    {services.map(s => (
                      <label key={s.id} onClick={(e) => e.stopPropagation()} style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '12px', cursor: 'pointer', borderBottom: '1px solid rgba(255,255,255,0.05)', margin: 0 }}>
                        <input 
                          type="checkbox" 
                          checked={newApptServices.includes(s.id)}
                          onChange={(e) => {
                            let updated = [...newApptServices];
                            if (e.target.checked) updated.push(s.id);
                            else updated = updated.filter(id => id !== s.id);
                            setNewApptServices(updated);

                            const total = updated.reduce((sum, id) => {
                              const serv = services.find(x => x.id === id);
                              return sum + (serv?.price || 0);
                            }, 0);
                            setNewPrice(total || '');
                          }}
                          style={{ width: '18px', height: '18px', accentColor: 'var(--primary-color)' }}
                        />
                        <span>{s.name} ({s.price}₺)</span>
                      </label>
                    ))}
                  </div>
                )}
              </div>

              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px' }}>Müşteri İsmi / Başlık</label>
                <input 
                  type="text" 
                  required 
                  list="customer-list"
                  placeholder="Müşteri seçin veya isim yaz..." 
                  value={newTitle} 
                  onChange={e => setNewTitle(e.target.value)} 
                />
                <datalist id="customer-list">
                  {customers.map(c => <option key={c.id} value={c.name} />)}
                </datalist>
              </div>
              
              <div style={{ display: 'flex', gap: '16px', marginBottom: '16px' }}>
                <div className="form-group" style={{ flex: 1 }}>
                  <label style={{ display: 'block', marginBottom: '8px' }}>Tarih</label>
                  <input type="date" required value={newDate} onChange={e => setNewDate(e.target.value)} />
                </div>
                <div className="form-group" style={{ flex: 1 }}>
                  <label style={{ display: 'block', marginBottom: '8px' }}>Başlangıç</label>
                  <input type="time" required value={newTime} onChange={e => setNewTime(e.target.value)} />
                </div>
              </div>

              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px' }}>Süre (Dakika)</label>
                <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                  <button type="button" onClick={() => setNewDuration(Math.max(15, newDuration - 15))} style={{ padding: '4px 12px', background: 'transparent', border: '1px solid var(--primary-color)', color: 'var(--primary-color)', borderRadius: '4px' }}>-</button>
                  <span style={{ fontWeight: 'bold' }}>{newDuration} dk</span>
                  <button type="button" onClick={() => setNewDuration(newDuration + 15)} style={{ padding: '4px 12px', background: 'transparent', border: '1px solid var(--primary-color)', color: 'var(--primary-color)', borderRadius: '4px' }}>+</button>
                  <span style={{ marginLeft: 'auto', color: 'var(--text-muted)', fontSize: '0.8rem' }}>Default (1 sa)</span>
                </div>
              </div>

              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px' }}>Fiyat (TL)</label>
                <input type="number" placeholder="Fiyat" value={newPrice} onChange={e => setNewPrice(e.target.value === '' ? '' : Number(e.target.value))} />
              </div>

              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px' }}>Diğer Kişiler (Opsiyonel)</label>
                <input type="text" placeholder="İsim ekle..." value={newOthers} onChange={e => setNewOthers(e.target.value)} />
              </div>

              <div className="form-group" style={{ marginBottom: '24px' }}>
                <label style={{ display: 'block', marginBottom: '8px' }}>Etiket Rengi</label>
                <div style={{ display: 'flex', gap: '8px' }}>
                  {['#ff9800', '#f44336', '#4caf50', '#2196f3', '#9c27b0'].map(color => (
                    <div 
                      key={color} 
                      onClick={() => setNewColor(color)}
                      style={{ 
                        width: '24px', height: '24px', borderRadius: '50%', background: color, cursor: 'pointer',
                        border: newColor === color ? '2px solid white' : 'none'
                      }}
                    />
                  ))}
                </div>
              </div>

              <button type="submit" disabled={isSubmitting} style={{ width: '100%', marginTop: '12px', padding: '12px', fontWeight: 'bold' }}>
                {isSubmitting ? 'Kaydediliyor...' : 'Kaydet'}
              </button>
              
              {editingAppointmentId && (
                <button 
                  type="button" 
                  onClick={() => handleDelete(editingAppointmentId)} 
                  style={{ width: '100%', marginTop: '12px', padding: '12px', fontWeight: 'bold', background: 'transparent', border: '1px solid #ff4444', color: '#ff4444' }}
                >
                  Randevuyu Sil
                </button>
              )}
            </form>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {deleteConfirmId && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.8)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000, padding: '20px' }}>
          <div className="glass-panel" style={{ width: '300px', textAlign: 'center' }}>
            <h3 style={{ marginBottom: '16px', color: '#ff4444' }}>Silmek İstediğinizden Emin Misiniz?</h3>
            <p style={{ color: 'var(--text-muted)', marginBottom: '24px', fontSize: '0.9rem' }}>Bu işlem geri alınamaz.</p>
            <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
              <button onClick={() => setDeleteConfirmId(null)} style={{ flex: 1, background: 'rgba(255,255,255,0.1)', color: 'white' }}>
                İptal
              </button>
              <button onClick={confirmDelete} style={{ flex: 1, background: '#ff4444', color: 'white' }}>
                Sil
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Pending Request Modal */}
      {pendingRequest && (
        <div 
          onClick={(e) => {
            if (e.target === e.currentTarget) {
              setPendingRequest(null);
              setIsSuggestingNewTime(false);
            }
          }}
          style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.85)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 2000, padding: '20px' }}
        >
          <div className="glass-panel" style={{ width: '400px', padding: '24px', border: '1px solid var(--primary-color)' }}>
            <h2 style={{ color: 'var(--primary-color)', marginBottom: '16px', textAlign: 'center' }}>🔔 Yeni Randevu Talebi!</h2>
            <div style={{ background: 'rgba(255,255,255,0.05)', padding: '16px', borderRadius: '8px', marginBottom: '24px' }}>
              <p style={{ margin: '8px 0' }}><strong>Müşteri:</strong> {pendingRequest.title}</p>
              <p style={{ margin: '8px 0' }}><strong>Hizmet:</strong> {pendingRequest.category}</p>
              <p style={{ margin: '8px 0' }}><strong>Tarih/Saat:</strong> {new Date(pendingRequest.date_time).toLocaleString('tr-TR')}</p>
              {pendingRequest.price > 0 && <p style={{ margin: '8px 0' }}><strong>Ücret:</strong> {pendingRequest.price} ₺</p>}
            </div>
            
            {isSuggestingNewTime ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                <label style={{ display: 'block', marginBottom: '4px', color: 'var(--primary-color)', fontWeight: 'bold' }}>Yeni Tarih/Saat Önerin:</label>
                <input 
                  type="datetime-local" 
                  value={suggestedDateTime} 
                  onChange={e => setSuggestedDateTime(e.target.value)} 
                  style={{ width: '100%', padding: '10px', borderRadius: '4px', background: '#222', color: 'white', border: '1px solid var(--primary-color)' }}
                />
                <div style={{ display: 'flex', gap: '12px', marginTop: '8px' }}>
                  <button onClick={() => setIsSuggestingNewTime(false)} style={{ flex: 1, background: 'rgba(255,255,255,0.1)', color: 'white', padding: '10px' }}>
                    İptal
                  </button>
                  <button onClick={handleSuggestNewTime} style={{ flex: 1, background: '#ff9800', color: 'black', fontWeight: 'bold', padding: '10px' }}>
                    Öneriyi Gönder
                  </button>
                </div>
              </div>
            ) : (
              <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
                <button onClick={handleRejectPending} style={{ flex: 1, background: '#f44336', color: 'white', fontWeight: 'bold', padding: '12px', minWidth: '80px' }}>
                  Reddet
                </button>
                <button 
                  onClick={() => {
                    const localDt = new Date(pendingRequest.date_time);
                    const tzOffset = localDt.getTimezoneOffset() * 60000;
                    const localISOTime = new Date(localDt.getTime() - tzOffset).toISOString().slice(0, 16);
                    setSuggestedDateTime(localISOTime);
                    setIsSuggestingNewTime(true);
                  }} 
                  style={{ flex: 1.5, background: '#ff9800', color: 'black', fontWeight: 'bold', padding: '12px', minWidth: '120px' }}
                >
                  Yeni Saat Öner
                </button>
                <button onClick={handleApprovePending} style={{ flex: 1, background: '#4caf50', color: 'black', fontWeight: 'bold', padding: '12px', minWidth: '80px' }}>
                  Onayla
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

const CustomersManager = () => {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [newName, setNewName] = useState('');
  const [newPhone, setNewPhone] = useState('');
  const [newNotes, setNewNotes] = useState('');
  const [adding, setAdding] = useState(false);

  // Modal State
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    const { data } = await supabase.from('customers').select('*').order('name');
    if (data) setCustomers(data);
    setLoading(false);
  };

  const handleAddCustomer = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName || !newPhone) return;
    
    setAdding(true);
    const id = crypto.randomUUID();
    await supabase.from('customers').insert({ id, name: newName, phone: newPhone, notes: newNotes });
    setNewName('');
    setNewPhone('');
    setNewNotes('');
    await fetchData();
    setAdding(false);
  };

  const handleDelete = async (id: string) => {
    if(confirm('Müşteriyi silmek istediğinize emin misiniz?')) {
      await supabase.from('customers').delete().eq('id', id);
      fetchData();
    }
  };

  return (
    <div>
      <h2>Müşteriler</h2>
      <p style={{ color: 'var(--text-muted)', marginBottom: '24px' }}>Kayıtlı müşterileriniz.</p>
      
      <div className="glass-panel" style={{ marginBottom: '24px' }}>
        <h3 style={{ marginTop: 0, marginBottom: '16px' }}>Yeni Müşteri Ekle</h3>
        <form onSubmit={handleAddCustomer} style={{ display: 'flex', gap: '16px', alignItems: 'flex-end' }}>
          <div style={{ flex: 1 }}>
            <label style={{ display: 'block', marginBottom: '8px', fontSize: '0.9rem', color: 'var(--text-muted)' }}>Ad Soyad</label>
            <input type="text" value={newName} onChange={e => setNewName(e.target.value)} required placeholder="Örn: Veli Yılmaz" />
          </div>
          <div style={{ flex: 1 }}>
            <label style={{ display: 'block', marginBottom: '8px', fontSize: '0.9rem', color: 'var(--text-muted)' }}>Telefon</label>
            <input type="tel" value={newPhone} onChange={e => setNewPhone(e.target.value)} required placeholder="05XX XXX XX XX" />
          </div>
          <div style={{ flex: 1 }}>
            <label style={{ display: 'block', marginBottom: '8px', fontSize: '0.9rem', color: 'var(--text-muted)' }}>Not / Tercih</label>
            <input type="text" value={newNotes} onChange={e => setNewNotes(e.target.value)} placeholder="Örn: Yanlar 3 numara" />
          </div>
          <button type="submit" disabled={adding} style={{ padding: '12px 24px', height: '45px' }}>
            {adding ? 'Ekleniyor...' : 'Ekle'}
          </button>
        </form>
      </div>

      {loading ? <p>Yükleniyor...</p> : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '16px' }}>
          {customers.map(c => (
            <div 
              key={c.id} 
              className="glass-panel" 
              style={{ position: 'relative', cursor: 'pointer' }}
              onClick={() => setSelectedCustomer(c)}
            >
              <h3 style={{ margin: '0 0 8px 0', color: 'var(--primary-color)' }}>{c.name}</h3>
              <p style={{ margin: 0, color: 'var(--text-muted)' }}>{c.phone}</p>
              <button 
                onClick={(e) => { e.stopPropagation(); handleDelete(c.id); }}
                style={{ position: 'absolute', top: '16px', right: '16px', padding: '8px', background: 'transparent', color: '#ff4444' }}>
                <Trash2 size={16} />
              </button>
            </div>
          ))}
        </div>
      )}

      {selectedCustomer && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.8)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="glass-panel" style={{ width: '400px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
              <h3 style={{ margin: 0, color: 'var(--primary-color)' }}>Müşteri Detayları</h3>
              <button onClick={() => setSelectedCustomer(null)} style={{ background: 'transparent', padding: 0, color: 'var(--text-light)' }}><X size={24} /></button>
            </div>
            
            <div style={{ marginBottom: '16px' }}>
              <label style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>Ad Soyad</label>
              <p style={{ margin: '4px 0 0 0', fontSize: '1.1rem' }}>{selectedCustomer.name}</p>
            </div>
            
            <div style={{ marginBottom: '16px' }}>
              <label style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>Telefon</label>
              <p style={{ margin: '4px 0 0 0', fontSize: '1.1rem' }}>{selectedCustomer.phone}</p>
            </div>

            <div style={{ marginBottom: '24px' }}>
              <label style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>Notlar / Tercihler</label>
              <p style={{ margin: '4px 0 0 0', fontSize: '1.1rem' }}>{/* Since Customer type doesn't have notes, we omit it or type it as any */}
                {(selectedCustomer as any).notes || 'Not bulunmuyor.'}
              </p>
            </div>

            <button onClick={() => setSelectedCustomer(null)} style={{ width: '100%', background: 'var(--surface-color-light)', color: 'var(--text-light)' }}>
              Kapat
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

const ServicesManager = () => {
  const [services, setServices] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    const { data } = await supabase.from('services').select('*').order('name');
    if (data) setServices(data);
    setLoading(false);
  };

  const updatePrice = async (id: string, newPrice: number) => {
    await supabase.from('services').update({ price: newPrice }).eq('id', id);
    fetchData();
  }

  return (
    <div>
      <h2>Hizmetler ve Fiyatlar</h2>
      <p style={{ color: 'var(--text-muted)', marginBottom: '24px' }}>Hizmet fiyatlarını güncelleyebilirsiniz.</p>
      
      {loading ? <p>Yükleniyor...</p> : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: '16px' }}>
          {services.map(s => (
            <div key={s.id} className="glass-panel" style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <h3 style={{ margin: 0 }}>{s.name}</h3>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <input 
                  type="number" 
                  defaultValue={s.price} 
                  onBlur={(e) => updatePrice(s.id, Number(e.target.value))}
                  style={{ width: '100px' }}
                /> ₺
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

interface Visit {
  id: string;
  customer_id: string;
  customer_name?: string;
  barber_id: string;
  date_time: string;
  total_price: number;
  payment_method: string;
  status: string;
  services: string[];
}

const VisitsManager = () => {
  const [visits, setVisits] = useState<Visit[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [barbers, setBarbers] = useState<Barber[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    const { data: cData } = await supabase.from('customers').select('*');
    if (cData) setCustomers(cData);
    
    const { data: bData } = await supabase.from('barbers').select('*');
    if (bData) setBarbers(bData);

    const { data: vData } = await supabase.from('visits').select('*').order('date_time', { ascending: false });
    if (vData) setVisits(vData);
    setLoading(false);
  };

  const handleDelete = async (id: string) => {
    if(confirm('Adisyonu silmek istediğinize emin misiniz?')) {
      await supabase.from('visits').delete().eq('id', id);
      fetchData();
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <div>
          <h2 style={{ margin: 0 }}>Adisyonlar</h2>
          <p style={{ color: 'var(--text-muted)', margin: '8px 0 0' }}>Geçmiş işlemleri ve ödemeleri görüntüleyin.</p>
        </div>
      </div>
      
      {loading ? <p>Yükleniyor...</p> : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {visits.map(v => (
            <div key={v.id} className="glass-panel" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h3 style={{ margin: '0 0 8px 0' }}>
                  {customers.find(c => c.id === v.customer_id)?.name || v.customer_name || 'Bilinmiyor'} 
                  <span style={{ margin: '0 8px', color: 'var(--text-muted)' }}>-</span>
                  {v.total_price} ₺
                </h3>
                <p style={{ margin: 0, color: 'var(--text-muted)', fontSize: '0.9rem' }}>
                  {format(parseISO(v.date_time), 'd MMM yyyy HH:mm', { locale: tr })} | 
                  Ödeme: {v.payment_method} | 
                  Berber: {barbers.find(b => b.id === v.barber_id)?.name || 'Bilinmiyor'}
                </p>
                {v.services && v.services.length > 0 && (
                  <div style={{ marginTop: '8px', display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                    {v.services.map((s, i) => (
                      <span key={i} style={{ fontSize: '0.75rem', padding: '4px 8px', background: 'rgba(255,255,255,0.1)', borderRadius: '4px' }}>{s}</span>
                    ))}
                  </div>
                )}
              </div>
              <button onClick={() => handleDelete(v.id)} style={{ background: 'transparent', color: '#ff4444' }}>
                <Trash2 size={18} />
              </button>
            </div>
          ))}
          {visits.length === 0 && <p>Henüz adisyon yok.</p>}
        </div>
      )}
    </div>
  );
};

const FinanceManager = () => {
  const [visits, setVisits] = useState<Visit[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [barbers, setBarbers] = useState<Barber[]>([]);
  
  const currentYear = new Date().getFullYear();
  const currentMonth = new Date().getMonth();
  
  const [selectedYear, setSelectedYear] = useState<number>(currentYear);
  const [selectedMonth, setSelectedMonth] = useState<number>(currentMonth);
  const [loading, setLoading] = useState(true);

  const months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];
  const years = Array.from({length: 5}, (_, i) => currentYear - i);

  useEffect(() => {
    fetchData();
  }, [selectedYear, selectedMonth]);

  const fetchData = async () => {
    setLoading(true);
    // Determine month bounds
    const startDate = new Date(selectedYear, selectedMonth, 1).toISOString();
    const endDate = new Date(selectedYear, selectedMonth + 1, 0, 23, 59, 59).toISOString();

    const { data: vData } = await supabase
      .from('visits')
      .select('*')
      .eq('status', 'Tamamlandı')
      .gte('date_time', startDate)
      .lte('date_time', endDate)
      .order('date_time', { ascending: false });
    
    if (vData) setVisits(vData);

    const { data: cData } = await supabase.from('customers').select('*');
    if (cData) setCustomers(cData);

    const { data: bData } = await supabase.from('barbers').select('*');
    if (bData) setBarbers(bData);

    setLoading(false);
  };

  const totalRevenue = visits.reduce((sum, v) => sum + (v.total_price || 0), 0);
  
  // Bugunku ciro hesabi (sadece secili ay ve yil bugune uyuyorsa hesaplamak mantikli ama her zaman gosterebiliriz)
  const today = new Date();
  const todayVisits = visits.filter(v => {
    const d = new Date(v.date_time);
    return d.getDate() === today.getDate() && d.getMonth() === today.getMonth() && d.getFullYear() === today.getFullYear();
  });
  const todayRevenue = todayVisits.reduce((sum, v) => sum + (v.total_price || 0), 0);

  // Odeme yontemi dagilimi
  const paymentMethods: Record<string, number> = {};
  visits.forEach(v => {
    const m = v.payment_method || 'Belirtilmedi';
    paymentMethods[m] = (paymentMethods[m] || 0) + (v.total_price || 0);
  });

  // Berber cirolari
  const barberRevenues: Record<string, number> = {};
  visits.forEach(v => {
    const b = barbers.find(bar => bar.id === v.barber_id)?.name || 'Bilinmiyor';
    barberRevenues[b] = (barberRevenues[b] || 0) + (v.total_price || 0);
  });

  return (
    <div>
      <h2>Finans & Ödemeler</h2>
      <p style={{ color: 'var(--text-muted)', marginBottom: '24px' }}>İşletmenizin gelir özetini ve ciro dağılımlarını buradan takip edebilirsiniz.</p>
      
      <div style={{ display: 'flex', gap: '24px', marginBottom: '24px' }}>
        <div style={{ flex: 1 }}>
          <label style={{ display: 'block', marginBottom: '8px', fontSize: '0.8rem', color: 'var(--gold-medium)', fontWeight: 'bold' }}>YIL SEÇİMİ</label>
          <select 
            value={selectedYear} 
            onChange={e => setSelectedYear(parseInt(e.target.value))}
            style={{ width: '100%', padding: '12px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', color: 'white', borderRadius: '8px' }}
          >
            {years.map(y => <option key={y} value={y}>{y}</option>)}
          </select>
        </div>
        <div style={{ flex: 1 }}>
          <label style={{ display: 'block', marginBottom: '8px', fontSize: '0.8rem', color: 'var(--gold-medium)', fontWeight: 'bold' }}>AY SEÇİMİ</label>
          <select 
            value={selectedMonth} 
            onChange={e => setSelectedMonth(parseInt(e.target.value))}
            style={{ width: '100%', padding: '12px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', color: 'white', borderRadius: '8px' }}
          >
            {months.map((m, i) => <option key={i} value={i}>{m}</option>)}
          </select>
        </div>
      </div>

      <div style={{ display: 'flex', gap: '24px', marginBottom: '24px' }}>
        <div className="glass-panel" style={{ flex: 1 }}>
          <p style={{ color: 'var(--text-muted)', margin: 0, fontSize: '0.9rem' }}>Aylık Toplam Ciro</p>
          <h2 style={{ color: 'var(--gold-primary)', margin: '8px 0 0 0' }}>{totalRevenue.toFixed(2)} ₺</h2>
        </div>
        <div className="glass-panel" style={{ flex: 1 }}>
          <p style={{ color: 'var(--text-muted)', margin: 0, fontSize: '0.9rem' }}>Bugünkü Ciro</p>
          <h2 style={{ color: 'white', margin: '8px 0 0 0' }}>{todayRevenue.toFixed(2)} ₺</h2>
        </div>
        <div className="glass-panel" style={{ flex: 1 }}>
          <p style={{ color: 'var(--text-muted)', margin: 0, fontSize: '0.9rem' }}>İşlem Sayısı</p>
          <h2 style={{ color: 'white', margin: '8px 0 0 0' }}>{visits.length}</h2>
        </div>
      </div>

      <div style={{ display: 'flex', gap: '24px', marginBottom: '24px' }}>
        <div className="glass-panel" style={{ flex: 1 }}>
          <h3 style={{ color: 'var(--gold-primary)', marginTop: 0, marginBottom: '16px' }}>Ödeme Yöntemleri Dağılımı</h3>
          {Object.entries(paymentMethods).length > 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {Object.entries(paymentMethods).map(([method, amount]) => (
                <div key={method} style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '8px', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                  <span style={{ color: 'var(--text-light)' }}>{method}</span>
                  <span style={{ fontWeight: 'bold' }}>{amount.toFixed(2)} ₺</span>
                </div>
              ))}
            </div>
          ) : <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>Bu ayda bir ödeme mevcut değil.</p>}
        </div>

        <div className="glass-panel" style={{ flex: 1 }}>
          <h3 style={{ color: 'var(--gold-primary)', marginTop: 0, marginBottom: '16px' }}>Berber Ciro Dağılımı</h3>
          {Object.entries(barberRevenues).length > 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {Object.entries(barberRevenues).map(([barber, amount]) => (
                <div key={barber} style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '8px', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                  <span style={{ color: 'var(--text-light)' }}>{barber}</span>
                  <span style={{ fontWeight: 'bold' }}>{amount.toFixed(2)} ₺</span>
                </div>
              ))}
            </div>
          ) : <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>Bu ayda bir ödeme mevcut değil.</p>}
        </div>
      </div>

      <div className="glass-panel">
        <h3 style={{ color: 'var(--gold-primary)', marginTop: 0, marginBottom: '16px' }}>Aylık İşlem Listesi</h3>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: '700px' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
                <th style={{ padding: '12px', color: 'var(--text-muted)' }}>Tarih</th>
                <th style={{ padding: '12px', color: 'var(--text-muted)' }}>Üye (Müşteri)</th>
                <th style={{ padding: '12px', color: 'var(--text-muted)' }}>Hizmetler</th>
                <th style={{ padding: '12px', color: 'var(--text-muted)' }}>Berber</th>
                <th style={{ padding: '12px', color: 'var(--text-muted)' }}>Yöntem</th>
                <th style={{ padding: '12px', color: 'var(--text-muted)' }}>Tutar</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={6} style={{ padding: '16px', textAlign: 'center' }}>Yükleniyor...</td></tr>
              ) : visits.length === 0 ? (
                <tr><td colSpan={6} style={{ padding: '16px', textAlign: 'center', color: 'var(--text-muted)' }}>Bu ayda bir ödeme mevcut değil.</td></tr>
              ) : (
                visits.map(v => {
                  const customerName = customers.find(c => c.id === v.customer_id)?.name || v.customer_name || 'Bilinmiyor';
                  const barberName = barbers.find(b => b.id === v.barber_id)?.name || 'Bilinmiyor';
                  
                  return (
                    <tr key={v.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                      <td style={{ padding: '12px' }}>{format(new Date(v.date_time), 'dd MMM yyyy HH:mm', { locale: tr })}</td>
                      <td style={{ padding: '12px', fontWeight: 'bold' }}>{customerName}</td>
                      <td style={{ padding: '12px' }}>{v.services?.join(', ') || '-'}</td>
                      <td style={{ padding: '12px' }}>{barberName}</td>
                      <td style={{ padding: '12px' }}>{v.payment_method}</td>
                      <td style={{ padding: '12px', color: 'var(--gold-primary)', fontWeight: 'bold' }}>{v.total_price} ₺</td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

const RequestsManager = () => {
  const [requests, setRequests] = useState<Appointment[]>([]);
  const [barbers, setBarbers] = useState<Barber[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);

  const [suggestingRequestId, setSuggestingRequestId] = useState<string | null>(null);
  const [suggestedDateTimeList, setSuggestedDateTimeList] = useState('');

  const playDingDong = () => {
    try {
      initAudio();
      const ctx = sharedAudioCtx;
      if (!ctx) return;
      
      // Ding (A5)
      const osc1 = ctx.createOscillator();
      const gain1 = ctx.createGain();
      osc1.type = 'sine';
      osc1.frequency.setValueAtTime(880, ctx.currentTime);
      gain1.gain.setValueAtTime(0.5, ctx.currentTime);
      gain1.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.5);
      osc1.connect(gain1);
      gain1.connect(ctx.destination);
      osc1.start(ctx.currentTime);
      osc1.stop(ctx.currentTime + 0.5);

      // Dong (E5)
      const osc2 = ctx.createOscillator();
      const gain2 = ctx.createGain();
      osc2.type = 'sine';
      osc2.frequency.setValueAtTime(659.25, ctx.currentTime + 0.3);
      gain2.gain.setValueAtTime(0.5, ctx.currentTime + 0.3);
      gain2.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 1.0);
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.start(ctx.currentTime + 0.3);
      osc2.stop(ctx.currentTime + 1.0);
    } catch (e) {
      console.error('Audio play error:', e);
    }
  };

  useEffect(() => {
    fetchData();

    // Subscribe to realtime changes in appointments to keep requests synced
    const channel = supabase
      .channel('web:requests')
      .on('postgres_changes' as any, { event: '*', schema: 'public', table: 'appointments' }, (payload: any) => {
        console.log('Admin Appointments Realtime:', payload);
        fetchData();
        if (payload.eventType === 'INSERT') {
          playDingDong();
        }
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const fetchData = async () => {
    setLoading(true);
    const { data: bData } = await supabase.from('barbers').select('*');
    if (bData) setBarbers(bData);

    const { data: cData } = await supabase.from('customers').select('*');
    if (cData) setCustomers(cData);

    const { data: rData } = await supabase
      .from('appointments')
      .select('*')
      .in('status', ['bekliyor', 'saat_onerildi', 'onaylandı', 'iptal', 'reddedildi'])
      .eq('is_dismissed_from_requests', false)
      .order('date_time', { ascending: true });
    
    if (rData) setRequests(rData);
    setLoading(false);
  };

  const handleApprove = async (id: string) => {
    await supabase.from('appointments').update({ status: 'onaylandı' }).eq('id', id);
    fetchData();
  };

  const handleReject = async (id: string) => {
    if (confirm('Bu randevu talebini reddetmek istediğinize emin misiniz?')) {
      await supabase.from('appointments').update({ status: 'reddedildi' }).eq('id', id);
      fetchData();
    }
  };

  const handleSuggestNewTimeList = async (id: string) => {
    if (!suggestedDateTimeList) return;
    const isoDateTime = new Date(suggestedDateTimeList).toISOString();
    await supabase.from('appointments').update({
      date_time: isoDateTime,
      status: 'saat_onerildi'
    }).eq('id', id);
    setSuggestingRequestId(null);
    fetchData();
  };

  const handleDismiss = async (id: string) => {
    await supabase.from('appointments').update({ is_dismissed_from_requests: true }).eq('id', id);
    fetchData();
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <div>
          <h2 style={{ margin: 0 }}>Bekleyen Randevu Talepleri</h2>
          <p style={{ color: 'var(--text-muted)', margin: '8px 0 0' }}>Müşterilerin onay bekleyen randevu isteklerini yönetin.</p>
        </div>
      </div>

      {loading ? <p>Yükleniyor...</p> : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {requests.map(r => (
            <div key={r.id} className="glass-panel" style={{ position: 'relative', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              {(r.status === 'onaylandı' || r.status === 'iptal' || r.status === 'reddedildi') && (
                <button 
                  onClick={() => handleDismiss(r.id)} 
                  style={{ position: 'absolute', top: '4px', right: '4px', background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', fontSize: '1.2rem', padding: '4px' }}
                  title="Listeden Kaldır"
                >
                  ✕
                </button>
              )}
              <div>
                <h3 style={{ margin: '0 0 8px 0', color: 'var(--primary-color)' }}>
                  {r.title}
                </h3>
                <p style={{ margin: 0, color: 'var(--text-color)', fontSize: '0.95rem', fontWeight: 500 }}>
                  Hizmet: {r.category} | Berber: {barbers.find(b => b.id === r.barber_id)?.name || 'Bilinmiyor'}
                </p>
                <p style={{ margin: '4px 0 0 0', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
                  Tarih/Saat: {format(new Date(r.date_time), 'dd MMM yyyy HH:mm', { locale: tr })}
                </p>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end' }}>
                <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
                  {suggestingRequestId === r.id ? (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', alignItems: 'flex-end' }}>
                      <input 
                        type="datetime-local" 
                        value={suggestedDateTimeList} 
                        onChange={e => setSuggestedDateTimeList(e.target.value)} 
                        style={{ padding: '6px', fontSize: '0.9rem', borderRadius: '4px', background: '#222', border: '1px solid var(--primary-color)', color: 'white' }} 
                      />
                      <div style={{ display: 'flex', gap: '8px' }}>
                        <button 
                          onClick={() => setSuggestingRequestId(null)} 
                          style={{ padding: '6px 12px', background: 'rgba(255,255,255,0.1)', color: 'white', fontWeight: 'bold', fontSize: '0.85rem' }}
                        >
                          İptal
                        </button>
                        <button 
                          onClick={() => handleSuggestNewTimeList(r.id)} 
                          style={{ padding: '6px 12px', background: '#ff9800', color: 'black', fontWeight: 'bold', fontSize: '0.85rem' }}
                        >
                          Gönder
                        </button>
                      </div>
                    </div>
                  ) : r.status === 'saat_onerildi' ? (
                    <div style={{ padding: '8px 16px', background: 'rgba(255, 152, 0, 0.1)', color: '#ff9800', border: '1px solid #ff9800', borderRadius: '4px', fontWeight: 'bold', fontSize: '0.9rem' }}>
                      Müşteri Yanıtı Bekleniyor
                    </div>
                  ) : r.status === 'onaylandı' ? (
                    <div style={{ padding: '8px 16px', background: 'rgba(76, 175, 80, 0.1)', color: '#4caf50', border: '1px solid #4caf50', borderRadius: '4px', fontWeight: 'bold', fontSize: '0.9rem' }}>
                      Onaylandı
                    </div>
                  ) : r.status === 'iptal' || r.status === 'reddedildi' ? (
                    <div style={{ padding: '8px 16px', background: 'rgba(244, 67, 54, 0.1)', color: '#f44336', border: '1px solid #f44336', borderRadius: '4px', fontWeight: 'bold', fontSize: '0.9rem' }}>
                      İptal Edildi
                    </div>
                  ) : (
                    <>
                      <button 
                        onClick={() => handleReject(r.id)} 
                        style={{ background: 'transparent', border: '1px solid #ff4444', color: '#ff4444', padding: '8px 16px', fontWeight: 'bold' }}
                      >
                        Reddet
                      </button>
                      <button 
                        onClick={() => {
                          const localDt = new Date(r.date_time);
                          const tzOffset = localDt.getTimezoneOffset() * 60000;
                          const localISOTime = new Date(localDt.getTime() - tzOffset).toISOString().slice(0, 16);
                          setSuggestedDateTimeList(localISOTime);
                          setSuggestingRequestId(r.id);
                        }} 
                        style={{ background: 'transparent', border: '1px solid #ff9800', color: '#ff9800', padding: '8px 16px', fontWeight: 'bold' }}
                      >
                        Saat Öner
                      </button>
                      <button 
                        onClick={() => handleApprove(r.id)} 
                        style={{ background: 'var(--primary-color)', color: 'black', padding: '8px 16px', fontWeight: 'bold' }}
                      >
                        Onayla
                      </button>
                    </>
                  )}
                </div>
                {(() => {
                  const customer = customers.find(c => c.id === r.customer_id);
                  const phone = customer?.phone || '';
                  if (!phone) return null;
                  
                  const handleCall = () => window.open(`tel:${phone}`, '_self');
                  const handleWhatsApp = () => {
                    const cleanPhone = phone.replace(/\D/g, '');
                    const finalPhone = cleanPhone.startsWith('90') ? cleanPhone : (cleanPhone.startsWith('0') ? '9' + cleanPhone : '90' + cleanPhone);
                    window.open(`https://wa.me/${finalPhone}`, '_blank');
                  };

                  return (
                    <div style={{ display: 'flex', gap: '8px', marginTop: '12px', justifyContent: 'flex-end' }}>
                      <button onClick={handleCall} style={{ background: '#333', border: 'none', color: 'white', padding: '6px 12px', borderRadius: '4px', display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.85rem' }}>
                        <Phone size={14} /> Ara
                      </button>
                      <button onClick={handleWhatsApp} style={{ background: '#25D366', border: 'none', color: 'white', padding: '6px 12px', borderRadius: '4px', display: 'flex', alignItems: 'center', gap: '6px', fontWeight: 'bold', fontSize: '0.85rem' }}>
                        <MessageCircle size={14} /> WhatsApp
                      </button>
                    </div>
                  );
                })()}
              </div>
            </div>
          ))}
          {requests.length === 0 && <p style={{ color: 'var(--text-muted)' }}>Bekleyen randevu talebi bulunmuyor.</p>}
        </div>
      )}
    </div>
  );
};

export default function Admin() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [unreadRequestsCount, setUnreadRequestsCount] = useState(0);
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    const auth = localStorage.getItem('adminAuth');
    if (auth === 'true') setIsAuthenticated(true);
  }, []);

  useEffect(() => {
    if (!isAuthenticated) return;

    // Initial fetch of unread count
    const fetchInitialUnread = async () => {
      const { count } = await supabase
        .from('appointments')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'bekliyor');
      setUnreadRequestsCount(count || 0);
    };
    fetchInitialUnread();

    // Subscribe to realtime changes in appointments to keep unread count updated
    const channel = supabase
      .channel('root:unread-requests')
      .on('postgres_changes' as any, { event: 'INSERT', schema: 'public', table: 'appointments' }, (payload: any) => {
        const newAppt = payload.new;
        if (newAppt && newAppt.status === 'bekliyor') {
          // Play notification sound
          new Audio('https://assets.mixkit.co/active_storage/sfx/2869/2869-500.wav').play().catch(() => {});
          if (location.pathname !== '/admin/requests') {
            setUnreadRequestsCount(prev => prev + 1);
          }
        }
      })
      .on('postgres_changes' as any, { event: '*', schema: 'public', table: 'appointments' }, () => {
        fetchInitialUnread();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [isAuthenticated, location.pathname]);

  useEffect(() => {
    if (location.pathname === '/admin/requests') {
      setUnreadRequestsCount(0);
    }
  }, [location.pathname]);

  const handleLogin = () => {
    setIsAuthenticated(true);
    navigate('/admin');
  };

  const handleLogout = () => {
    localStorage.removeItem('adminAuth');
    setIsAuthenticated(false);
    navigate('/admin/login');
  };

  if (!isAuthenticated) {
    return <AdminLogin onLogin={handleLogin} />;
  }

  return (
    <div style={{ display: 'flex', minHeight: '80vh', gap: '24px', margin: '-40px', padding: '40px', background: 'var(--bg-color)' }}>
      <Sidebar onLogout={handleLogout} unreadCount={unreadRequestsCount} />
      <div style={{ flex: 1, padding: '24px', overflowY: 'auto' }}>
        <Routes>
          <Route path="/" element={<AppointmentsManager />} />
          <Route path="/customers" element={<CustomersManager />} />
          <Route path="/services" element={<ServicesManager />} />
          <Route path="/visits" element={<VisitsManager />} />
          <Route path="/requests" element={<RequestsManager />} />
          <Route path="/finance" element={<FinanceManager />} />
        </Routes>
      </div>
    </div>
  );
}
