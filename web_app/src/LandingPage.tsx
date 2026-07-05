import { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import './LandingPage.css';

export default function LandingPage() {
  const navigate = useNavigate();
  const particlesRef = useRef<HTMLDivElement>(null);

  // Scroll reveal
  useEffect(() => {
    const reveals = document.querySelectorAll('.lp-reveal, .lp-reveal-left, .lp-reveal-right');
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) entry.target.classList.add('lp-visible');
      });
    }, { threshold: 0.1, rootMargin: '0px 0px -50px 0px' });
    reveals.forEach(el => observer.observe(el));
    return () => observer.disconnect();
  }, []);

  // Particles
  useEffect(() => {
    const container = particlesRef.current;
    if (!container) return;
    for (let i = 0; i < 22; i++) {
      const p = document.createElement('div');
      p.className = 'lp-particle';
      p.style.left = Math.random() * 100 + '%';
      p.style.animationDuration = (8 + Math.random() * 12) + 's';
      p.style.animationDelay = (Math.random() * 10) + 's';
      const sz = (1 + Math.random() * 3) + 'px';
      p.style.width = sz;
      p.style.height = sz;
      container.appendChild(p);
    }
    return () => { if (container) container.innerHTML = ''; };
  }, []);

  // Navbar scroll
  useEffect(() => {
    const nav = document.getElementById('lp-navbar');
    const onScroll = () => nav?.classList.toggle('lp-scrolled', window.scrollY > 60);
    window.addEventListener('scroll', onScroll);
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const scrollTo = (id: string) => {
    document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' });
  };

  const services = [
    { icon: '✂️', image: '/service_haircut.jpg', name: 'Saç Kesim', duration: '~30 dk', price: '₺600' },
    { icon: '🪒', image: '/service_beard.jpg', name: 'Sakal Kesimi', duration: '~20 dk', price: '₺300' },
    { icon: '💎', image: '/service_haircut.jpg', name: 'Saç + Sakal', duration: '~50 dk', price: '₺800' },
    { icon: '👦', image: '/service_child_haircut.jpg', name: 'Çocuk Kesim', duration: '~25 dk', price: '₺400' },
    { icon: '💆', image: '/service_wash_male.jpg', name: 'Yıkama & Fön', duration: '~25 dk', price: '₺300' },
    { icon: '🌿', image: '/service_mask.jpg', name: 'Yüz Maskesi', duration: '~20 dk', price: '₺200' },
    { icon: '🧴', image: '/service_hair_mask.jpg', name: 'Saç Maskesi', duration: '~30 dk', price: '₺200' },
    { icon: '🎨', image: '/service_hair_dye_male.jpg', name: 'Saç Boyama', duration: '~60 dk', price: '₺800' },
    { icon: '🖌️', image: '/service_beard_dye.jpg', name: 'Sakal Boyama', duration: '~30 dk', price: '₺400' },
    { icon: '💫', image: '/service_haircut.jpg', name: 'Keratin', duration: '~90 dk', price: '₺800' },
    { icon: '🕯️', image: '/service_beard.jpg', name: 'Ağda', duration: '~15 dk', price: '₺100' },
  ];

  const team = [
    { initial: 'S', name: 'Saffet Yılmaz', role: 'Baş Berber', phone: '05446253453', wa: '905446253453' },
    { initial: 'O', name: 'Onur Yılmaz', role: 'Uzman Berber', phone: '05059790553', wa: '905059790553' },
    { initial: 'M', name: 'Musab Torlak', role: 'Berber & Stilist', phone: '05414693340', wa: '905414693340' },
  ];

  const hours = [
    { day: 'Pazartesi', time: '08:00 – 22:00', closed: false },
    { day: 'Salı', time: '08:00 – 22:00', closed: false },
    { day: 'Çarşamba', time: '08:00 – 22:00', closed: false },
    { day: 'Perşembe', time: '08:00 – 22:00', closed: false },
    { day: 'Cuma', time: '08:00 – 22:00', closed: false },
    { day: 'Cumartesi', time: '08:00 – 22:00', closed: false },
    { day: 'Pazar', time: 'Kapalı', closed: true },
  ];

  return (
    <div className="lp">
      {/* NAVBAR */}
      <nav id="lp-navbar" className="lp-nav">
        <a href="#lp-hero" className="lp-logo">
          <img src="/logo.png" alt="Logo" />
          <div className="lp-logo-text">
            <span className="lp-brand">SO Yılmaz</span>
            <span className="lp-sub">Berber & Kuaför</span>
          </div>
        </a>
        <ul className="lp-links">
          <li><button onClick={() => scrollTo('lp-about')}>Hakkımızda</button></li>
          <li><button onClick={() => scrollTo('lp-services')}>Hizmetler</button></li>
          <li><button onClick={() => scrollTo('lp-team')}>Ekibimiz</button></li>
          <li><button onClick={() => scrollTo('lp-hours')}>Saatler</button></li>
        </ul>
        <button className="lp-nav-cta" onClick={() => navigate('/randevu')}>
          Randevu Al
        </button>
      </nav>

      {/* HERO */}
      <section id="lp-hero" className="lp-hero">
        <div className="lp-hero-bg" style={{ backgroundImage: "url('/interior_salon.jpg')" }} />
        <div className="lp-hero-overlay" />
        <div className="lp-particles" ref={particlesRef} />

        <div className="lp-hero-content">
          <div className="lp-badge">
            <span className="lp-dot" />
            Premium Berber & Kuaför
            <span className="lp-dot" />
          </div>
          <h1 className="lp-hero-title">
            SO <span className="lp-gold">Yılmaz</span><br />Berber
          </h1>
          <p className="lp-hero-sub">
            Uzman berberlerimizle saç ve sakal bakımında premium deneyim.<br />
            Her kesimde kendinizi en iyi hissedin.
          </p>
          <div className="lp-hero-actions">
            <button className="lp-btn-primary" onClick={() => navigate('/randevu')}>
              📅 Randevu Al
            </button>
            <button className="lp-btn-secondary" onClick={() => scrollTo('lp-services')}>
              Hizmetlerimiz ↓
            </button>
          </div>
        </div>

        <div className="lp-scroll-hint">
          <span>Keşfet</span>
          <div className="lp-scroll-line" />
        </div>

        <div className="lp-hero-stats">
          {[
            { num: '3+', label: 'Uzman Berber' },
            { num: '11+', label: 'Hizmet Çeşidi' },
            { num: '6/7', label: 'Gün Açık' },
            { num: '100%', label: 'Müşteri Memnuniyeti' },
          ].map(s => (
            <div key={s.label} className="lp-stat">
              <div className="lp-stat-num">{s.num}</div>
              <div className="lp-stat-label">{s.label}</div>
            </div>
          ))}
        </div>
      </section>

      {/* ABOUT */}
      <section id="lp-about" className="lp-section lp-about">
        <div className="lp-container">
          <div className="lp-about-grid">
            {/* Images column — 2×2 grid */}
            <div className="lp-reveal-left lp-images-col">
              <div className="lp-about-photo-grid">
                <div className="lp-about-photo-wrap">
                  <img src="/work2.jpg" alt="Berberlerimiz çalışırken" className="lp-about-photo" />
                  <div className="lp-about-photo-label">✂️ Uzman Ekibimiz</div>
                </div>
                <div className="lp-about-photo-wrap">
                  <img src="/work1.jpg" alt="Yüz bakımı hizmeti" className="lp-about-photo" />
                  <div className="lp-about-photo-label">💆 Özenli Bakım</div>
                </div>
                <div className="lp-about-photo-wrap">
                  <img src="/interior_salon.jpg" alt="Salon iç mekan" className="lp-about-photo" />
                  <div className="lp-about-photo-label">🏪 Modern Salonumuz</div>
                </div>
                <div className="lp-about-photo-wrap">
                  <img src="/exterior.jpg" alt="Salon dış görünüm" className="lp-about-photo" />
                  <div className="lp-about-photo-label">📍 Dükkanımız</div>
                </div>
              </div>
              <div className="lp-rating-strip">
                <div className="lp-stars">★★★★★</div>
                <div style={{ color: '#aaa', fontSize: '13px' }}>Müşterilerimizin değerlendirmesi</div>
              </div>
            </div>
            {/* Text column */}
            <div className="lp-reveal-right lp-about-text">
              <div className="lp-section-label">Biz Kimiz</div>
              <h2 className="lp-section-title">
                Tarzınızı Biz<br /><span className="lp-gold">Şekillendiriyoruz</span>
              </h2>
              <p className="lp-section-sub">
                SO Yılmaz Berber olarak, her müşterimize premium ve kişiselleştirilmiş bir bakım deneyimi sunuyoruz.
                Uzman ekibimiz ve modern ekipmanlarımızla saç ve sakal bakımını bir sanat formuna dönüştürüyoruz.
              </p>
              <div className="lp-features">
                {[
                  { icon: '✂️', text: 'Uzman Kesim' },
                  { icon: '🪒', text: 'Sakal Bakımı' },
                  { icon: '☕', text: 'Ücretsiz Kahve' },
                  { icon: '📱', text: 'Online Randevu' },
                ].map(f => (
                  <div key={f.text} className="lp-feat">
                    <div className="lp-feat-icon">{f.icon}</div>
                    <span>{f.text}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* GALLERY strip */}
      <div className="lp-gallery-strip">
        <img src="/work2.jpg" alt="Berberlerimiz çalışırken" />
        <img src="/interior_salon.jpg" alt="İç Mekan" />
        <img src="/work1.jpg" alt="Yüz bakımı" />
        <img src="/exterior.jpg" alt="Dükkan girişi" />
        <img src="/coffee_corner.jpg" alt="Kahve köşesi" />
      </div>

      {/* SERVICES */}
      <section id="lp-services" className="lp-section">
        <div className="lp-container">
          <div className="lp-section-header lp-reveal">
            <div className="lp-section-label lp-center">Ne Yapıyoruz</div>
            <h2 className="lp-section-title lp-center">Hizmetlerimiz</h2>
            <p className="lp-section-sub lp-center">Saç ve sakal bakımından boyamaya kadar geniş hizmet yelpazemizle yanınızdayız.</p>
          </div>
          <div className="lp-services-grid">
            {services.map((s, i) => (
              <div key={s.name} className={`lp-service-card lp-reveal lp-delay-${(i % 3) + 1}`}>
                <div className="lp-svc-left">
                  {s.image ? (
                    <img src={s.image} alt={s.name} className="lp-svc-img" />
                  ) : (
                    <div className="lp-svc-icon">{s.icon}</div>
                  )}
                  <div>
                    <div className="lp-svc-name">{s.name}</div>
                    <div className="lp-svc-dur">{s.duration}</div>
                  </div>
                </div>
                <div className="lp-svc-price">{s.price}</div>
              </div>
            ))}
          </div>
          <div style={{ textAlign: 'center', marginTop: '40px' }}>
            <button className="lp-btn-primary" onClick={() => navigate('/randevu')}>
              Hemen Randevu Al ✂️
            </button>
          </div>
        </div>
      </section>

      {/* TEAM */}
      <section id="lp-team" className="lp-section lp-team-section">
        <div className="lp-container">
          <div className="lp-reveal" style={{ textAlign: 'center', marginBottom: '64px' }}>
            <div className="lp-section-label lp-center">Profesyoneller</div>
            <h2 className="lp-section-title lp-center">Ekibimiz</h2>
          </div>
          <div className="lp-team-grid">
            {team.map((t, i) => (
              <div key={t.name} className={`lp-team-card lp-reveal lp-delay-${i + 1}`}>
                <div className="lp-team-avatar">
                  <div className="lp-team-initial">{t.initial}</div>
                  <div className="lp-team-scissors">✂</div>
                </div>
                <div className="lp-team-info">
                  <div className="lp-team-name">{t.name}</div>
                  <div className="lp-team-role">{t.role}</div>
                  <div className="lp-team-divider" />
                  <div className="lp-team-btns">
                    <a href={`https://wa.me/${t.wa}`} target="_blank" rel="noreferrer" className="lp-team-btn lp-wa">
                      💬 WhatsApp
                    </a>
                    <a href={`tel:${t.phone}`} className="lp-team-btn lp-call">
                      📞 Ara
                    </a>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* WHY US */}
      <section className="lp-section">
        <div className="lp-container">
          <div className="lp-reveal" style={{ textAlign: 'center' }}>
            <div className="lp-section-label lp-center">Neden Biz</div>
            <h2 className="lp-section-title lp-center">Farkımız Ne?</h2>
          </div>
          <div className="lp-why-grid">
            {[
              { icon: '🏆', title: 'Uzman Kadro', text: 'Yıllarca deneyim sahibi, alanında uzman berberlerimizle her ziyaretiniz özel bir deneyime dönüşür.' },
              { icon: '✨', title: 'Premium Ürünler', text: 'Saç ve sakal bakımında yalnızca en kaliteli markaların ürünlerini kullanıyoruz.' },
              { icon: '☕', title: 'Ücretsiz Kahve', text: 'Beklerken Türk kahvesi, filtre kahve ya da espresso ile ikramlıyız.' },
              { icon: '💈', title: 'Klasik & Modern', text: 'Klasik berber geleneklerini modern tekniklerle birleştirerek en iyi sonucu elde ediyoruz.' },
            ].map((w, i) => (
              <div key={w.title} className={`lp-why-card lp-reveal lp-delay-${i + 1}`}>
                <span className="lp-why-icon">{w.icon}</span>
                <h3 className="lp-why-title">{w.title}</h3>
                <p className="lp-why-text">{w.text}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="lp-section lp-cta-section">
        <div className="lp-cta-glow" />
        <div className="lp-container">
          <div className="lp-cta-content lp-reveal">
            <div className="lp-section-label lp-center">Hemen Başlayın</div>
            <h2 className="lp-section-title lp-center">
              Randevunuzu<br /><span className="lp-gold">Bugün Alın</span>
            </h2>
            <p className="lp-cta-desc">
              Pazar günleri dışında her gün hizmetinizdeyiz. Hızlıca randevu oluşturun, beklemeyin.
            </p>
            <div className="lp-cta-actions">
              <button className="lp-btn-primary" onClick={() => navigate('/randevu')}>
                📅 Online Randevu Al
              </button>
              <a href="https://wa.me/905446253453?text=Merhaba!%20Randevu%20almak%20istiyorum." target="_blank" rel="noreferrer" className="lp-btn-wa">
                <svg viewBox="0 0 24 24" width="18" height="18" fill="white"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z" /></svg>
                WhatsApp
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* HOURS */}
      <section id="lp-hours" className="lp-section">
        <div className="lp-container">
          <div className="lp-hours-grid">
            <div className="lp-reveal-left">
              <div className="lp-section-label">Çalışma Düzeni</div>
              <h2 className="lp-section-title">
                Çalışma<br /><span className="lp-gold">Saatlerimiz</span>
              </h2>
              <div className="lp-hours-table">
                {hours.map(h => (
                  <div key={h.day} className={`lp-hours-row${h.closed ? ' lp-closed' : ''}`}>
                    <span className="lp-hours-day">{h.day}</span>
                    <span className="lp-hours-time">{h.time}</span>
                  </div>
                ))}
              </div>
            </div>
            <div className="lp-reveal-right">
              <img src="/exterior.jpg" alt="Dükkan Girişi" className="lp-hours-img" />
              <div className="lp-location-card">
                <div className="lp-location-name">📍 SO Yılmaz Berber & Kuaför</div>
                <div style={{ color: 'var(--text-muted)', fontSize: '13.5px', marginBottom: '16px', lineHeight: '1.5' }}>
                  Taşdelen Mah. Turgut Özal Cad. Bulvar Sk. No:1/3B <br />
                  Çekmeköy / İstanbul
                </div>
                <div className="lp-location-phones">
                  <a href="tel:05446253453">📞 0544 625 34 53</a>
                  <a href="tel:05059790553">📞 0505 979 05 53</a>
                  <a href="tel:05414693340">📞 0541 469 33 40</a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* FOOTER */}
      <footer className="lp-footer">
        <div className="lp-container">
          <div className="lp-footer-grid">
            <div className="lp-footer-brand">
              <div className="lp-footer-name">SO Yılmaz Berber</div>
              <p className="lp-footer-desc">Premium berber ve kuaför hizmetleri. Uzman kadromuzla saç ve sakal bakımında fark yaratıyoruz.</p>
            </div>
            <div className="lp-footer-col">
              <h4>Hizmetler</h4>
              <ul>
                <li><button onClick={() => scrollTo('lp-services')}>Saç Kesim</button></li>
                <li><button onClick={() => scrollTo('lp-services')}>Sakal Bakımı</button></li>
                <li><button onClick={() => scrollTo('lp-services')}>Saç Boyama</button></li>
                <li><button onClick={() => scrollTo('lp-services')}>Keratin</button></li>
              </ul>
            </div>
            <div className="lp-footer-col">
              <h4>İletişim</h4>
              <ul>
                <li><a href="tel:05446253453">Saffet: 0544 625 34 53</a></li>
                <li><a href="tel:05059790553">Onur: 0505 979 05 53</a></li>
                <li><a href="tel:05414693340">Musab: 0541 469 33 40</a></li>
                <li><a href="https://wa.me/905446253453" target="_blank" rel="noreferrer">WhatsApp</a></li>
              </ul>
            </div>
          </div>
          <div className="lp-footer-bottom">
            <span>© 2026 <span className="lp-gold">SO Yılmaz Berber</span>. Tüm hakları saklıdır.</span>
            <span>Pazar günleri kapalıyız.</span>
          </div>
        </div>
      </footer>

      {/* WhatsApp Float */}
      <a href="https://wa.me/905446253453?text=Merhaba!%20Randevu%20almak%20istiyorum." target="_blank" rel="noreferrer" className="lp-wa-float" aria-label="WhatsApp">
        <svg viewBox="0 0 24 24" fill="white"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z" /></svg>
      </a>
    </div>
  );
}
