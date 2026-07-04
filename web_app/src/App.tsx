import { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useNavigate, useParams, useLocation } from 'react-router-dom';
import { Scissors, User, Phone, ChevronLeft, ChevronRight } from 'lucide-react';
import { supabase } from './lib/supabase';
import { format, addDays, startOfDay, isSameDay } from 'date-fns';
import { tr } from 'date-fns/locale';
import Admin from './Admin';
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
const Home = () => {
  const [barbers, setBarbers] = useState<Barber[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchBarbers = async () => {
      const { data } = await supabase.from('barbers').select('*');
      if (data) setBarbers(data);
      setLoading(false);
    };
    fetchBarbers();
  }, []);

  return (
    <div className="animate-fade-in">
      <div style={{ textAlign: 'center', marginBottom: '40px' }}>
        <h1 style={{ fontSize: '2.5rem', marginBottom: '16px', color: '#fff' }}>Yılmaz Hair Barber</h1>
        <p style={{ color: 'var(--text-muted)', fontSize: '1.1rem' }}>Randevu almak istediğiniz berberi seçin</p>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px' }}>Yükleniyor...</div>
      ) : (
        <div className="barber-grid">
          {barbers.map(barber => (
            <Link to={`/book/${barber.id}`} key={barber.id} className="glass-panel barber-card">
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
  
  const [selectedService, setSelectedService] = useState<string>('');
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

  // Generate 30-min time slots from 09:00 to 20:00
  const generateTimeSlots = () => {
    const slots = [];
    let currentHour = 9;
    let currentMinute = 0;
    
    while (currentHour < 20) {
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
    if (!selectedService || !selectedTime || !customerName || !customerPhone || !barberId) return;
    
    setSubmitting(true);
    try {
      const service = services.find(s => s.id === selectedService);
      
      // Upsert customer (simplified)
      const customerId = crypto.randomUUID();
      await supabase.from('customers').insert({
        id: customerId,
        name: customerName,
        phone: customerPhone
      });

      const [hours, minutes] = selectedTime.split(':').map(Number);
      const appTime = new Date(selectedDate);
      appTime.setHours(hours, minutes, 0, 0);

      const appointmentId = crypto.randomUUID();
      await supabase.from('appointments').insert({
        id: appointmentId,
        title: customerName,
        category: service?.name || 'Randevu',
        date_time: appTime.toISOString(),
        duration_minutes: 30, // Default duration
        price: service?.price || 0,
        color_hex: '#4CAF50', // Default green
        status: 'bekliyor', // pending approval
        customer_id: customerId,
        barber_id: barberId
      });

      alert('Randevu talebiniz başarıyla alındı!');
      navigate('/');
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
            <button className="date-btn" onClick={() => setSelectedDate(addDays(selectedDate, -1))} disabled={isSameDay(selectedDate, new Date())}>
              <ChevronLeft size={20} />
            </button>
            <h3 style={{ margin: 0, minWidth: '150px', textAlign: 'center', color: '#fff' }}>
              {format(selectedDate, 'd MMMM yyyy', { locale: tr })}
            </h3>
            <button className="date-btn" onClick={() => setSelectedDate(addDays(selectedDate, 1))}>
              <ChevronRight size={20} />
            </button>
          </div>

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
            </div>

            <div className="form-group">
              <label><Scissors size={16} style={{ verticalAlign: 'middle', marginRight: '8px' }} />Hizmet Seçimi</label>
              <select required value={selectedService} onChange={e => setSelectedService(e.target.value)}>
                <option value="">Seçiniz</option>
                {services.map(s => (
                  <option key={s.id} value={s.id}>{s.name} - {s.price} ₺</option>
                ))}
              </select>
            </div>

            <button type="submit" disabled={submitting || !selectedTime || !selectedService} style={{ width: '100%', marginTop: '16px', padding: '16px' }}>
              {submitting ? 'Gönderiliyor...' : 'Randevu Talebini Gönder'}
            </button>
            {!selectedTime && <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', textAlign: 'center', marginTop: '12px' }}>Lütfen sol taraftan bir saat seçin</p>}
          </form>
        </div>
      </div>
    </div>
  );
};

const AppContent = () => {
  const location = useLocation();
  const isAdmin = location.pathname.startsWith('/admin');

  return (
    <div className="app-container">
      {!isAdmin && (
        <header>
          <div className="logo">
            <img src="/logo.png" alt="Logo" style={{ width: '40px', height: '40px', borderRadius: '8px' }} />
            SO Yılmaz Berber
          </div>
          <div style={{ color: 'var(--text-muted)' }}>Müşteri Randevu Sistemi</div>
        </header>
      )}
      <main style={{ padding: isAdmin ? 0 : undefined }}>
        <Routes>
          <Route path="/" element={<div className="container"><Home /></div>} />
          <Route path="/book/:barberId" element={<div className="container"><Booking /></div>} />
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
