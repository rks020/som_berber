import { useState, useEffect } from 'react';
import { Routes, Route, Link, useNavigate, useLocation } from 'react-router-dom';
import { supabase } from './lib/supabase';
import { LayoutDashboard, Users, Scissors, CalendarCheck, LogOut, Check, X, Trash2, Wallet } from 'lucide-react';
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

const Sidebar = ({ onLogout }: { onLogout: () => void }) => {
  const location = useLocation();
  const menu = [
    { name: 'Randevular', path: '/admin', icon: <CalendarCheck size={20} /> },
    { name: 'Müşteriler', path: '/admin/customers', icon: <Users size={20} /> },
    { name: 'Hizmetler', path: '/admin/services', icon: <Scissors size={20} /> },
    { name: 'Adisyonlar', path: '/admin/visits', icon: <LayoutDashboard size={20} /> },
    { name: 'Finans', path: '/admin/finance', icon: <Wallet size={20} /> },
  ];

  return (
    <div style={{ width: '250px', borderRight: '1px solid rgba(255,255,255,0.1)', padding: '24px', display: 'flex', flexDirection: 'column' }}>
      <h2 style={{ color: 'var(--primary-color)', marginBottom: '32px' }}>SOM Admin</h2>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '8px' }}>
        {menu.map(item => (
          <Link 
            key={item.path} 
            to={item.path} 
            style={{ 
              display: 'flex', alignItems: 'center', gap: '12px', padding: '12px', 
              borderRadius: '8px', 
              backgroundColor: location.pathname === item.path || (location.pathname === '/admin/' && item.path === '/admin') ? 'var(--primary-color)' : 'transparent',
              color: location.pathname === item.path || (location.pathname === '/admin/' && item.path === '/admin') ? '#000' : 'var(--text-color)',
              fontWeight: location.pathname === item.path ? 600 : 400
            }}
          >
            {item.icon} {item.name}
          </Link>
        ))}
      </div>
      <button onClick={onLogout} style={{ background: 'transparent', color: '#ff4444', border: '1px solid #ff4444', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
        <LogOut size={18} /> Çıkış Yap
      </button>
    </div>
  );
};

import { startOfWeek, addDays, getHours, getDay } from 'date-fns';

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
  const [selectedSlot, setSelectedSlot] = useState<{date: Date, hour: number} | null>(null);
  const [newApptCustomer, setNewApptCustomer] = useState('');
  const [newApptService, setNewApptService] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    fetchData();
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
    if (!selectedSlot || !selectedBarberId || !newApptCustomer || !newApptService) return;
    
    setIsSubmitting(true);
    const serviceDetails = services.find(s => s.id === newApptService);
    const slotTime = new Date(selectedSlot.date);
    slotTime.setHours(selectedSlot.hour, 0, 0, 0);

    const id = crypto.randomUUID();
    await supabase.from('appointments').insert({
      id,
      title: customers.find(c => c.id === newApptCustomer)?.name || 'Bilinmiyor',
      category: serviceDetails?.name || '',
      date_time: slotTime.toISOString(),
      status: 'onaylandı',
      customer_id: newApptCustomer,
      barber_id: selectedBarberId
    });

    setNewApptCustomer('');
    setNewApptService('');
    setIsModalOpen(false);
    await fetchData();
    setIsSubmitting(false);
  };

  const handleUpdateStatus = async (id: string, status: string) => {
    await supabase.from('appointments').update({ status }).eq('id', id);
    fetchData();
  };

  const handleDelete = async (id: string) => {
    if(confirm('Emin misiniz?')) {
      await supabase.from('appointments').delete().eq('id', id);
      fetchData();
    }
  };

  // Build calendar data
  const weekStart = startOfWeek(currentDate, { weekStartsOn: 1 }); // Monday
  const days = Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));
  const hours = Array.from({ length: 17 }, (_, i) => i + 7); // 7 to 23

  const filteredAppointments = appointments.filter(a => a.barber_id === selectedBarberId);

  const getAppointmentsForSlot = (date: Date, hour: number) => {
    return filteredAppointments.filter(app => {
      const appDate = parseISO(app.date_time);
      return appDate.getDate() === date.getDate() &&
             appDate.getMonth() === date.getMonth() &&
             appDate.getFullYear() === date.getFullYear() &&
             appDate.getHours() === hour;
    });
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '24px' }}>
        <div>
          <h2>Randevu Listesi</h2>
          <p style={{ color: 'var(--text-muted)' }}>Berber bazlı haftalık taslak ve randevu yönetimi.</p>
        </div>
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <button onClick={() => setCurrentDate(addDays(currentDate, -7))} style={{ background: 'var(--primary-color)', color: '#000', padding: '6px 12px' }}>&lt;</button>
          <span style={{ fontWeight: 'bold' }}>{format(weekStart, 'd MMM', { locale: tr })} - {format(addDays(weekStart, 6), 'd MMM yyyy', { locale: tr })}</span>
          <button onClick={() => setCurrentDate(addDays(currentDate, 7))} style={{ background: 'var(--primary-color)', color: '#000', padding: '6px 12px' }}>&gt;</button>
        </div>
      </div>
      
      {/* Barber Tabs */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '24px', overflowX: 'auto', paddingBottom: '8px' }}>
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
            {days.map((day, i) => (
              <div key={i} style={{ padding: '4px', textAlign: 'center', fontWeight: 'bold', color: 'var(--primary-color)', borderRight: '1px solid rgba(255,255,255,0.05)' }}>
                <span style={{ fontSize: '0.75rem' }}>{format(day, 'EEE', { locale: tr })}</span><br/>
                <span style={{ fontSize: '0.65rem', color: 'var(--text-muted)' }}>{format(day, 'd MMM', { locale: tr })}</span>
              </div>
            ))}
          </div>

          <div style={{ minWidth: '800px' }}>
            {hours.map(hour => (
              <div key={hour} style={{ display: 'grid', gridTemplateColumns: '50px repeat(7, 1fr)', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                <div style={{ padding: '4px 0', fontSize: '0.7rem', color: 'var(--text-muted)', borderRight: '1px solid rgba(255,255,255,0.05)', textAlign: 'center' }}>
                  {hour.toString().padStart(2, '0')}:00
                </div>
                {days.map((day, dIdx) => {
                  const apps = getAppointmentsForSlot(day, hour);
                  return (
                    <div 
                      key={dIdx} 
                      onClick={() => { setSelectedSlot({ date: day, hour }); setIsModalOpen(true); }}
                      style={{ borderRight: '1px solid rgba(255,255,255,0.05)', padding: '1px', minHeight: '28px', cursor: 'pointer' }}
                    >
                      {apps.map(app => (
                        <div 
                          key={app.id} 
                          onClick={(e) => e.stopPropagation()}
                          title={`${app.title} - ${app.category}`}
                          style={{ 
                            background: app.status === 'bekliyor' ? '#ff9800' : 'var(--primary-color)', 
                            color: '#000', 
                            padding: '2px 4px', 
                            borderRadius: '4px', 
                            marginBottom: '1px',
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'center'
                          }}
                        >
                          <div style={{ fontWeight: 'bold', fontSize: '0.65rem', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            {app.title} - {app.category}
                          </div>
                          <div style={{ display: 'flex', gap: '4px' }}>
                            {app.status === 'bekliyor' && (
                              <button onClick={() => handleUpdateStatus(app.id, 'onaylandı')} style={{ background: 'transparent', padding: '0', color: '#000', border: 'none' }}>
                                <Check size={12} />
                              </button>
                            )}
                            <button onClick={() => handleDelete(app.id)} style={{ background: 'transparent', padding: '0', color: '#ff4444', border: 'none' }}>
                              <X size={12} />
                            </button>
                          </div>
                        </div>
                      ))}
                    </div>
                  );
                })}
              </div>
            ))}
          </div>
        </div>
      )}

      {isModalOpen && selectedSlot && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.8)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="glass-panel" style={{ width: '400px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
              <h3 style={{ margin: 0 }}>Yeni Randevu Ekle</h3>
              <button onClick={() => setIsModalOpen(false)} style={{ background: 'transparent', padding: 0, color: 'var(--text-light)' }}><X size={24} /></button>
            </div>
            
            <p style={{ color: 'var(--primary-color)', marginBottom: '16px' }}>
              {format(selectedSlot.date, 'd MMMM yyyy', { locale: tr })} - {selectedSlot.hour.toString().padStart(2, '0')}:00
            </p>

            <form onSubmit={handleCreateAppointment}>
              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px' }}>Müşteri</label>
                <select required value={newApptCustomer} onChange={e => setNewApptCustomer(e.target.value)}>
                  <option value="">Seçiniz</option>
                  {customers.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </div>
              
              <div className="form-group" style={{ marginBottom: '24px' }}>
                <label style={{ display: 'block', marginBottom: '8px' }}>Hizmet</label>
                <select required value={newApptService} onChange={e => setNewApptService(e.target.value)}>
                  <option value="">Seçiniz</option>
                  {services.map(s => <option key={s.id} value={s.id}>{s.name} ({s.price}₺)</option>)}
                </select>
              </div>

              <button type="submit" disabled={isSubmitting} style={{ width: '100%' }}>
                {isSubmitting ? 'Kaydediliyor...' : 'Randevu Oluştur'}
              </button>
            </form>
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
                  {customers.find(c => c.id === v.customer_id)?.name || 'Bilinmiyor'} 
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
                  const customerName = customers.find(c => c.id === v.customer_id)?.name || 'Bilinmiyor';
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

export default function Admin() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    const auth = localStorage.getItem('adminAuth');
    if (auth === 'true') setIsAuthenticated(true);
  }, []);

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
      <Sidebar onLogout={handleLogout} />
      <div style={{ flex: 1, padding: '24px', overflowY: 'auto' }}>
        <Routes>
          <Route path="/" element={<AppointmentsManager />} />
          <Route path="/customers" element={<CustomersManager />} />
          <Route path="/services" element={<ServicesManager />} />
          <Route path="/visits" element={<VisitsManager />} />
          <Route path="/finance" element={<FinanceManager />} />
        </Routes>
      </div>
    </div>
  );
}
