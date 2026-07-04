import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';
import '../models/barber.dart';
import '../models/service.dart';
import '../models/visit.dart';
import '../models/appointment.dart';
import '../services/notification_service.dart';

class SalonProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Customer> _customers = [];
  List<Barber> _barbers = [];
  List<Service> _services = [];
  List<Visit> _visits = [];
  List<AppointmentModel> _appointments = [];

  bool _isLoading = true;

  // Getters
  List<Customer> get customers => _customers;
  List<Barber> get barbers => _barbers;
  List<Service> get services => _services;
  List<Visit> get visits => _visits;
  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;

  AppointmentModel? pendingRequestNotification;

  void clearPendingRequestNotification() {
    pendingRequestNotification = null;
    notifyListeners();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _fetchInitialData();
      _setupRealtime();
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchInitialData() async {
    final cRes = await _supabase.from('customers').select();
    _customers = cRes.map((e) => Customer.fromMap(e)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final bRes = await _supabase.from('barbers').select();
    if (bRes.isEmpty) {
      final defaultBarbers = [
        Barber(id: 'saffet', name: 'Saffet Yılmaz', phone: '0544 625 34 53'),
        Barber(id: 'onur', name: 'Onur Yılmaz', phone: '0505 979 05 53'),
        Barber(id: 'musab', name: 'Musab Torlak', phone: '0541 469 33 40'),
      ];
      for (var b in defaultBarbers) {
        await _supabase.from('barbers').insert(b.toMap());
      }
      _barbers = defaultBarbers;
    } else {
      _barbers = bRes.map((e) => Barber.fromMap(e)).toList();
    }

    final sRes = await _supabase.from('services').select();
    if (sRes.isEmpty) {
      final defaultServices = [
        Service(id: 'sac_kesim', name: 'Saç Kesim', price: 600.0),
        Service(id: 'sakal_kesimi', name: 'Sakal Kesimi', price: 300.0),
        Service(id: 'sac_sakal', name: 'Saç Sakal', price: 800.0),
        Service(id: 'cocuk_kesim', name: 'Çocuk Kesim', price: 400.0),
        Service(id: 'yikama_fon', name: 'Yıkama Ve Fön', price: 300.0),
        Service(id: 'yuz_maskesi', name: 'Yüz Maskesi', price: 200.0),
        Service(id: 'sac_maskesi', name: 'Saç Maskesi', price: 200.0),
        Service(id: 'sac_boyama', name: 'Saç Boyama', price: 800.0),
        Service(id: 'sakal_boyama', name: 'Sakal Boyama', price: 400.0),
        Service(id: 'keratin', name: 'Keratin', price: 800.0),
        Service(id: 'agda', name: 'Ağda', price: 100.0),
      ];
      for (var s in defaultServices) {
        await _supabase.from('services').insert(s.toMap());
      }
      _services = defaultServices;
    } else {
      _services = sRes.map((e) => Service.fromMap(e)).toList();
    }

    final vRes = await _supabase.from('visits').select();
    _visits = vRes.map((e) => Visit.fromMap(e)).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final aRes = await _supabase.from('appointments').select();
    _appointments = aRes.map((e) => AppointmentModel.fromMap(e)).toList();
  }

  void _setupRealtime() {
    // Use a single channel to avoid duplicate subscription conflicts
    _supabase
        .channel('public:all-tables')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          callback: (payload) {
            _fetchInitialData().then((_) {
              notifyListeners();

              // Check if it's a new appointment with pending approval
              if (payload.eventType == PostgresChangeEvent.insert) {
                final newRecord = payload.newRecord;
                if (newRecord != null) {
                  final app = AppointmentModel.fromMap(newRecord);
                  if (app.status == 'bekliyor') {
                    // Trigger immediate local notification
                    NotificationService().showImmediateNotification(
                      app.id.hashCode,
                      '🔔 Yeni Randevu Talebi!',
                      '${app.title} - ${app.category} için onay bekliyor.',
                    );
                    pendingRequestNotification = app;
                    notifyListeners();
                  }
                }
              }
            });
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'customers',
          callback: (_) => _fetchInitialData().then((_) => notifyListeners()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'barbers',
          callback: (_) => _fetchInitialData().then((_) => notifyListeners()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'services',
          callback: (_) => _fetchInitialData().then((_) => notifyListeners()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'visits',
          callback: (_) => _fetchInitialData().then((_) => notifyListeners()),
        )
        .subscribe();
  }

  // --- CUSTOMER OPERATIONS ---
  Future<void> addCustomer(Customer customer) async {
    await _supabase.from('customers').insert(customer.toMap());
  }

  Future<void> updateCustomer(Customer customer) async {
    await _supabase.from('customers').update(customer.toMap()).eq('id', customer.id);
  }

  Future<void> deleteCustomer(String id) async {
    await _supabase.from('customers').delete().eq('id', id);
  }

  // --- BARBER OPERATIONS ---
  Future<void> addBarber(Barber barber) async {
    await _supabase.from('barbers').insert(barber.toMap());
  }

  Future<void> updateBarber(Barber barber) async {
    await _supabase.from('barbers').update(barber.toMap()).eq('id', barber.id);
  }

  Future<void> deleteBarber(String id) async {
    await _supabase.from('barbers').delete().eq('id', id);
  }

  // --- SERVICE OPERATIONS ---
  Future<void> addService(Service service) async {
    await _supabase.from('services').insert(service.toMap());
  }

  Future<void> updateService(Service service) async {
    await _supabase.from('services').update(service.toMap()).eq('id', service.id);
  }

  Future<void> deleteService(String id) async {
    await _supabase.from('services').delete().eq('id', id);
  }

  // --- VISIT OPERATIONS ---
  Future<void> addVisit(Visit visit) async {
    await _supabase.from('visits').insert(visit.toMap());
  }

  Future<void> updateVisit(Visit visit) async {
    await _supabase.from('visits').update(visit.toMap()).eq('id', visit.id);
  }

  Future<void> deleteVisit(String id) async {
    await _supabase.from('visits').delete().eq('id', id);
  }

  // --- APPOINTMENT OPERATIONS ---
  Future<void> addAppointment(AppointmentModel appointment) async {
    await _supabase.from('appointments').insert(appointment.toMap());
    await NotificationService().scheduleAppointmentNotification(
      appointment.id.hashCode,
      appointment.title,
      appointment.dateTime,
    );
  }

  Future<void> updateAppointment(AppointmentModel appointment) async {
    await _supabase.from('appointments').update(appointment.toMap()).eq('id', appointment.id);
    await NotificationService().cancelNotification(appointment.id.hashCode);
    await NotificationService().scheduleAppointmentNotification(
      appointment.id.hashCode,
      appointment.title,
      appointment.dateTime,
    );
  }

  Future<void> deleteAppointment(String id) async {
    await _supabase.from('appointments').delete().eq('id', id);
    await NotificationService().cancelNotification(id.hashCode);
  }

  // --- ANALYTICS & COMPUTATIONS ---

  List<Visit> getCompletedVisits() {
    return _visits.where((v) => v.status == 'Tamamlandı').toList();
  }

  double getDailyRevenue(DateTime date) {
    return getCompletedVisits()
        .where(
          (v) =>
              v.dateTime.year == date.year &&
              v.dateTime.month == date.month &&
              v.dateTime.day == date.day,
        )
        .fold(0.0, (sum, v) => sum + v.totalPrice);
  }

  double getWeeklyRevenue(DateTime date) {
    // Find the beginning of the week (Monday)
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final startOfMonday = DateTime(monday.year, monday.month, monday.day);
    final endOfWeek = startOfMonday.add(const Duration(days: 7));

    return getCompletedVisits()
        .where(
          (v) =>
              v.dateTime.isAfter(startOfMonday) &&
              v.dateTime.isBefore(endOfWeek),
        )
        .fold(0.0, (sum, v) => sum + v.totalPrice);
  }

  double getMonthlyRevenue(DateTime date) {
    return getCompletedVisits()
        .where(
          (v) => v.dateTime.year == date.year && v.dateTime.month == date.month,
        )
        .fold(0.0, (sum, v) => sum + v.totalPrice);
  }

  Map<String, double> getRevenueByPaymentMethod(DateTime start, DateTime end) {
    final map = {'Nakit': 0.0, 'Kart': 0.0, 'Veresiye': 0.0};
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final rangeVisits = getCompletedVisits().where(
      (v) => v.dateTime.isAfter(startDay) && v.dateTime.isBefore(endDay),
    );

    for (var v in rangeVisits) {
      final method = v.paymentMethod;
      if (map.containsKey(method)) {
        map[method] = map[method]! + v.totalPrice;
      } else {
        map[method] = v.totalPrice; // fallback for custom methods if any
      }
    }
    return map;
  }

  Map<String, double> getRevenueByBarber(DateTime start, DateTime end) {
    final Map<String, double> map = {};
    for (var barber in _barbers) {
      map[barber.name] = 0.0;
    }

    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final rangeVisits = getCompletedVisits().where(
      (v) => v.dateTime.isAfter(startDay) && v.dateTime.isBefore(endDay),
    );

    for (var v in rangeVisits) {
      final barberName = _barbers
          .firstWhere(
            (b) => b.id == v.barberId,
            orElse: () => Barber(id: '', name: 'Bilinmeyen', phone: ''),
          )
          .name;
      map[barberName] = (map[barberName] ?? 0.0) + v.totalPrice;
    }
    return map;
  }

  Map<String, int> getServiceCounts(DateTime start, DateTime end) {
    final Map<String, int> map = {};
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final rangeVisits = getCompletedVisits().where(
      (v) => v.dateTime.isAfter(startDay) && v.dateTime.isBefore(endDay),
    );

    for (var v in rangeVisits) {
      for (var serviceName in v.serviceNames) {
        map[serviceName] = (map[serviceName] ?? 0) + 1;
      }
    }
    return map;
  }

  List<Visit> getVisitsForCustomer(String customerId) {
    return _visits.where((v) => v.customerId == customerId).toList();
  }

  List<Visit> getVisitsForBarber(String barberId) {
    return _visits.where((v) => v.barberId == barberId).toList();
  }
}
