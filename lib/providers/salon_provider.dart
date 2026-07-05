import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';
import '../models/barber.dart';
import '../models/service.dart';
import '../models/visit.dart';
import '../models/appointment.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalonProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Customer> _customers = [];
  List<Barber> _barbers = [];
  List<Service> _services = [];
  List<Visit> _visits = [];
  List<AppointmentModel> _appointments = [];

  bool _isLoading = true;
  int _unreadRequestsCount = 0;
  bool _firstLoad = true;

  // Getters
  List<Customer> get customers => _customers;
  List<Barber> get barbers => _barbers;
  List<Service> get services => _services;
  List<Visit> get visits => _visits;
  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;
  int get unreadRequestsCount => _unreadRequestsCount;

  AppointmentModel? pendingRequestNotification;

  void clearUnreadRequestsCount() {
    _unreadRequestsCount = 0;
    notifyListeners();
  }

  void incrementUnreadRequestsCount() {
    _unreadRequestsCount++;
    notifyListeners();
  }

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

    if (_firstLoad) {
      _unreadRequestsCount = _appointments.where((a) => a.status == 'bekliyor').length;
      _firstLoad = false;
    }
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
            debugPrint('Realtime Event received: ${payload.eventType}');
            AppointmentModel? oldApp;
            if (payload.eventType == PostgresChangeEvent.update) {
              final newRecord = payload.newRecord;
              if (newRecord != null) {
                final app = AppointmentModel.fromMap(newRecord);
                try {
                  oldApp = _appointments.firstWhere((a) => a.id == app.id);
                  debugPrint('Found oldApp: ${oldApp.id}, status: ${oldApp.status}');
                } catch (e) {
                  debugPrint('Failed to find oldApp: $e');
                  oldApp = null;
                }
              }
            }

            _fetchInitialData().then((_) {
              notifyListeners();

              // Check if it's a new appointment with pending approval
              if (payload.eventType == PostgresChangeEvent.insert) {
                final newRecord = payload.newRecord;
                if (newRecord != null) {
                  final app = AppointmentModel.fromMap(newRecord);
                  if (app.status == 'bekliyor') {
                    SharedPreferences.getInstance().then((prefs) {
                      final isAdmin = prefs.getBool('is_admin_logged_in') ?? false;
                      debugPrint('Insert event: isAdmin=$isAdmin');
                      if (isAdmin) {
                        // Trigger immediate local notification for admin
                        NotificationService().showImmediateNotification(
                          app.id.hashCode,
                          '🔔 Yeni Randevu Talebi!',
                          '${app.title} - ${app.category} için onay bekliyor.',
                        );
                        pendingRequestNotification = app;
                        _unreadRequestsCount++;
                        notifyListeners();
                      }
                    });
                  }
                }
              }

              // Check if it's an update where appointment got approved or has new hour suggested
              if (payload.eventType == PostgresChangeEvent.update) {
                final newRecord = payload.newRecord;
                if (newRecord != null) {
                  final app = AppointmentModel.fromMap(newRecord);
                  debugPrint('Update event: app.id=${app.id}, app.status=${app.status}');
                  
                  if (oldApp != null) {
                    debugPrint('Comparing oldApp status (${oldApp.status}) vs new status (${app.status})');
                    if (oldApp.status != 'onaylandı' && app.status == 'onaylandı') {
                      SharedPreferences.getInstance().then((prefs) {
                        final savedCustomerId = prefs.getString('saved_customer_id');
                        debugPrint('Notification check: savedCustomerId=$savedCustomerId, app.customerId=${app.customerId}');
                        if (savedCustomerId != null && savedCustomerId == app.customerId) {
                          debugPrint('Triggering approved notification!');
                          NotificationService().showImmediateNotification(
                            app.id.hashCode,
                            '📅 Randevunuz Onaylandı!',
                            '${app.category} randevu talebiniz berber tarafından onaylandı.',
                          );
                        }
                      });
                    } else if (oldApp.status != 'saat_onerildi' && app.status == 'saat_onerildi') {
                      SharedPreferences.getInstance().then((prefs) {
                        final savedCustomerId = prefs.getString('saved_customer_id');
                        debugPrint('Notification check: savedCustomerId=$savedCustomerId, app.customerId=${app.customerId}');
                        if (savedCustomerId != null && savedCustomerId == app.customerId) {
                          debugPrint('Triggering new time notification!');
                          NotificationService().showImmediateNotification(
                            app.id.hashCode,
                            '⏰ Yeni Saat Önerisi',
                            'Berberiniz randevu için yeni bir saat önerdi. Kontrol etmek için tıklayın.',
                          );
                        }
                      });
                    }
                  } else {
                    debugPrint('oldApp was null, cannot compare status change.');
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

  // --- STORAGE OPERATIONS ---
  Future<String?> uploadBarberPhoto(String barberId, String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final extension = localPath.split('.').last;
      final storagePath = 'barbers/$barberId.$extension';

      await _supabase.storage.from('photos').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = _supabase.storage.from('photos').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading barber photo: $e');
      return null;
    }
  }

  Future<String?> uploadVisitPhoto(String visitId, String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final extension = localPath.split('.').last;
      final storagePath = 'visits/$visitId.$extension';

      await _supabase.storage.from('photos').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = _supabase.storage.from('photos').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading visit photo: $e');
      return null;
    }
  }

  // --- BARBER OPERATIONS ---
  Future<void> addBarber(Barber barber) async {
    String? finalPath = barber.profilePicturePath;
    if (finalPath != null && !finalPath.startsWith('http')) {
      final uploadedUrl = await uploadBarberPhoto(barber.id, finalPath);
      if (uploadedUrl != null) {
        finalPath = uploadedUrl;
      }
    }
    final updated = barber.copyWith(profilePicturePath: finalPath);
    await _supabase.from('barbers').insert(updated.toMap());
  }

  Future<void> updateBarber(Barber barber) async {
    String? finalPath = barber.profilePicturePath;
    if (finalPath != null && !finalPath.startsWith('http')) {
      final uploadedUrl = await uploadBarberPhoto(barber.id, finalPath);
      if (uploadedUrl != null) {
        finalPath = uploadedUrl;
      }
    }
    final updated = barber.copyWith(profilePicturePath: finalPath);
    await _supabase.from('barbers').update(updated.toMap()).eq('id', barber.id);
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
    String? finalPath = visit.photoPath;
    if (finalPath != null && !finalPath.startsWith('http')) {
      final uploadedUrl = await uploadVisitPhoto(visit.id, finalPath);
      if (uploadedUrl != null) {
        finalPath = uploadedUrl;
      }
    }
    final updated = visit.copyWith(photoPath: finalPath);
    await _supabase.from('visits').insert(updated.toMap());
  }

  Future<void> updateVisit(Visit visit) async {
    String? finalPath = visit.photoPath;
    if (finalPath != null && !finalPath.startsWith('http')) {
      final uploadedUrl = await uploadVisitPhoto(visit.id, finalPath);
      if (uploadedUrl != null) {
        finalPath = uploadedUrl;
      }
    }
    final updated = visit.copyWith(photoPath: finalPath);
    await _supabase.from('visits').update(updated.toMap()).eq('id', visit.id);
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
