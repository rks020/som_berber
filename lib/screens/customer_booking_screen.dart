import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
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
  Service? _selectedService;
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isSubmitting = false;

  List<String> _generateTimeSlots() {
    final slots = <String>[];
    for (int hour = 9; hour < 20; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
      slots.add('${hour.toString().padLeft(2, '0')}:30');
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
      final slotEnd = slotTime.add(const Duration(minutes: 30));

      if (slotStart.isBefore(appEnd) && slotEnd.isAfter(appStart)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _submitBooking(SalonProvider provider) async {
    if (_selectedTime == null || _selectedService == null || _nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final customerId = const Uuid().v4();
      final newCustomer = Customer(
        id: customerId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        createdAt: DateTime.now(),
      );
      
      await provider.addCustomer(newCustomer);

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

      final newApp = AppointmentModel(
        id: const Uuid().v4(),
        title: _nameController.text.trim(),
        category: _selectedService!.name,
        dateTime: appTime,
        durationMinutes: 30,
        price: _selectedService!.price,
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
                    final newDate = _selectedDate.subtract(const Duration(days: 1));
                    if (!newDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                      setState(() {
                        _selectedDate = newDate;
                        _selectedTime = null;
                      });
                    }
                  },
                ),
                Text(
                  DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDate),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                      _selectedTime = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
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
            DropdownButtonFormField<Service>(
              decoration: const InputDecoration(
                labelText: 'Hizmet Seçimi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.content_cut),
              ),
              value: _selectedService,
              items: provider.services.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text('${s.name} - ${s.price} ₺'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedService = val),
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
        ),
      ),
    );
  }
}
