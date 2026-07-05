import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/barber.dart';
import '../models/service.dart';
import '../models/appointment.dart';
import '../models/customer.dart';
import '../providers/salon_provider.dart';

class CustomerBookingScreen extends StatefulWidget {
  final Barber barber;
  const CustomerBookingScreen({super.key, required this.barber});

  @override
  State<CustomerBookingScreen> createState() => _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends State<CustomerBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  List<Service> _selectedServices = [];
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isSubmitting = false;
  String? _savedCustomerId;

  @override
  void initState() {
    super.initState();
    _loadSavedCustomer();
  }

  Future<void> _loadSavedCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('saved_customer_id');
    final savedName = prefs.getString('saved_customer_name');
    final savedPhone = prefs.getString('saved_customer_phone');
    if (savedId != null && mounted) {
      setState(() {
        _savedCustomerId = savedId;
        _nameController.text = savedName ?? '';
        _phoneController.text = savedPhone ?? '';
      });
    }
  }

  Future<void> _saveCustomerLocally(String id, String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_customer_id', id);
    await prefs.setString('saved_customer_name', name);
    await prefs.setString('saved_customer_phone', phone);
  }

  List<String> _generateTimeSlots() {
    final slots = <String>[];
    for (int hour = 8; hour <= 22; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
    }
    return slots;
  }

  bool _isSlotDisabled(String time, List<AppointmentModel> appointments) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final slotTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );

    if (slotTime.isBefore(DateTime.now())) return true;

    // Check overlap
    for (var app in appointments) {
      if (app.barberId != widget.barber.id) continue;
      
      final appStart = app.dateTime;
      final appEnd = app.dateTime.add(Duration(minutes: app.durationMinutes));
      
      final slotStart = slotTime;
      final slotEnd = slotTime.add(const Duration(hours: 1));

      if (slotStart.isBefore(appEnd) && slotEnd.isAfter(appStart)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _submitBooking(SalonProvider provider) async {
    if (_selectedDate.weekday == DateTime.sunday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pazar günleri kapalıyız')),
      );
      return;
    }

    if (_selectedTime == null || _selectedServices.isEmpty || _nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      String customerId;
      if (_savedCustomerId != null) {
        customerId = _savedCustomerId!;
        final newName = _nameController.text.trim();
        final newPhone = _phoneController.text.trim();
        final prefs = await SharedPreferences.getInstance();
        final oldName = prefs.getString('saved_customer_name') ?? '';
        final oldPhone = prefs.getString('saved_customer_phone') ?? '';
        
        if (oldName != newName || oldPhone != newPhone) {
          final updatedCustomer = Customer(
            id: customerId,
            name: newName,
            phone: newPhone,
            createdAt: DateTime.now(),
          );
          await provider.updateCustomer(updatedCustomer);
          await _saveCustomerLocally(customerId, newName, newPhone);
        }
      } else {
        customerId = const Uuid().v4();
        final newCustomer = Customer(
          id: customerId,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          createdAt: DateTime.now(),
        );
        await provider.addCustomer(newCustomer);
        await _saveCustomerLocally(customerId, newCustomer.name, newCustomer.phone);
      }

      final parts = _selectedTime!.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final appTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
        minute,
      );

      final combinedCategory = _selectedServices.map((s) => s.name).join(', ');
      final totalCombinedPrice = _selectedServices.fold<double>(0.0, (sum, s) => sum + s.price);

      final newApp = AppointmentModel(
        id: const Uuid().v4(),
        title: _nameController.text.trim(),
        category: combinedCategory,
        dateTime: appTime,
        durationMinutes: 60, // 1 hour slot
        price: totalCombinedPrice,
        colorHex: '#4CAF50', // Green for pending
        status: 'bekliyor',
        customerId: customerId,
        barberId: widget.barber.id,
      );

      await provider.addAppointment(newApp);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Randevu talebiniz başarıyla alındı!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalonProvider>(context);
    final timeSlots = _generateTimeSlots();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.barber.name} - Randevu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    DateTime newDate = _selectedDate.subtract(const Duration(days: 1));
                    if (newDate.weekday == DateTime.sunday) {
                      newDate = newDate.subtract(const Duration(days: 1));
                    }
                    if (!newDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                      setState(() {
                        _selectedDate = newDate;
                        _selectedTime = null;
                      });
                    }
                  },
                ),
                Column(
                  children: [
                    Text(
                      DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDate),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_selectedDate.weekday == DateTime.sunday)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.withOpacity(0.4)),
                        ),
                        child: const Text(
                          '🚫 Kapalı',
                          style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    DateTime newDate = _selectedDate.add(const Duration(days: 1));
                    if (newDate.weekday == DateTime.sunday) {
                      newDate = newDate.add(const Duration(days: 1));
                    }
                    setState(() {
                      _selectedDate = newDate;
                      _selectedTime = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
               if (_selectedDate.weekday == DateTime.sunday) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.redAccent, size: 50),
                    SizedBox(height: 16),
                    Text(
                      'Pazar Günleri Kapalıyız',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Salonumuz Pazar günleri hizmet vermemektedir. Lütfen diğer günleri seçiniz.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Time Slots
              const Text('Saat Seçin', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: timeSlots.map((time) {
                  final disabled = _isSlotDisabled(time, provider.appointments);
                  final selected = _selectedTime == time;
                  
                  return InkWell(
                    onTap: disabled ? null : () => setState(() => _selectedTime = time),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? Colors.amber : (disabled ? Colors.white10 : Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? Colors.amber : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          color: selected ? Colors.black : (disabled ? Colors.white30 : Colors.white),
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Form
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              const Text('Hizmet Seçimi (Birden fazla seçebilirsiniz)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  children: provider.services.map((s) {
                    final isChecked = _selectedServices.any((item) => item.id == s.id);
                    return CheckboxListTile(
                      activeColor: Colors.amber,
                      checkColor: Colors.black,
                      title: Text(s.name, style: const TextStyle(fontSize: 14, color: Colors.white)),
                      subtitle: Text('${s.price} ₺', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      value: isChecked,
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedServices.add(s);
                          } else {
                            _selectedServices.removeWhere((item) => item.id == s.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submitBooking(provider),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                child: _isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Randevu Talebini Gönder', style: TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
