import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'customer_list_screen.dart';
import 'barbers_screen.dart';
import 'services_screen.dart';
import 'appointment_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/salon_provider.dart';
import '../models/appointment.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isDialogShowing = false;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CustomerListScreen(),
    AppointmentScreen(),
    BarbersScreen(),
    ServicesScreen(),
  ];

  Future<void> _showPendingRequestDialog(BuildContext context, SalonProvider provider, AppointmentModel app) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final timeFormat = DateFormat('dd.MM.yyyy HH:mm');
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('🔔 Yeni Randevu Talebi!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Müşteri: ${app.title}', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Text('Hizmet: ${app.category}', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Text('Tarih/Saat: ${timeFormat.format(app.dateTime)}', style: const TextStyle(color: Colors.white)),
              if (app.price > 0) ...[
                const SizedBox(height: 8),
                Text('Ücret: ${app.price.toStringAsFixed(0)} ₺', style: const TextStyle(color: Colors.white)),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (context.mounted) Navigator.pop(context);
                await provider.deleteAppointment(app.id);
              },
              child: const Text('Reddet', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: app.dateTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('tr', 'TR'),
                );
                if (selectedDate == null) return;

                if (!context.mounted) return;
                final selectedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(app.dateTime),
                );
                if (selectedTime == null) return;

                final newDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                if (context.mounted) Navigator.pop(context);
                final updated = app.copyWith(
                  dateTime: newDateTime,
                  status: 'saat_onerildi',
                );
                await provider.updateAppointment(updated);
              },
              child: const Text('Saat Öner', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              onPressed: () async {
                if (context.mounted) Navigator.pop(context);
                final approved = app.copyWith(status: 'onaylandı');
                await provider.updateAppointment(approved);
              },
              child: const Text('Onayla', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalonProvider>(context);
    final pendingApp = provider.pendingRequestNotification;

    if (pendingApp != null && !_isDialogShowing) {
      _isDialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _showPendingRequestDialog(context, provider, pendingApp);
        if (mounted) {
          setState(() {
            _isDialogShowing = false;
          });
        }
        provider.clearPendingRequestNotification();
      });
    }

    if (_currentIndex == 0 && provider.unreadRequestsCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.clearUnreadRequestsCount();
      });
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: provider.unreadRequestsCount > 0
                ? Badge(
                    label: Text(provider.unreadRequestsCount.toString()),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.dashboard_outlined),
                  )
                : const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: 'Panel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Müşteriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Randevu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.face_retouching_natural_outlined),
            activeIcon: Icon(Icons.face_retouching_natural),
            label: 'Berberler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dry_cleaning_outlined),
            activeIcon: Icon(Icons.dry_cleaning),
            label: 'Fiyatlar',
          ),
        ],
      ),
    );
  }
}
