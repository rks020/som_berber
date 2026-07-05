import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../providers/salon_provider.dart';
import '../models/appointment.dart';
import '../models/barber.dart';
import 'customer_booking_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _loadCustomerId();
  }

  Future<void> _loadCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    final cId = prefs.getString('saved_customer_id');
    setState(() {
      _customerId = cId;
    });

    if (cId != null) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await Supabase.instance.client
              .from('customers')
              .update({'fcm_token': token})
              .eq('id', cId);
        }
      } catch (e) {
        debugPrint('FCM Token update error: $e');
      }
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final formatted = clean.startsWith('0') ? '90${clean.substring(1)}' : clean.startsWith('90') ? clean : '90$clean';
    final url = Uri.parse('https://wa.me/$formatted');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('WhatsApp başlatılamadı: $e');
    }
  }

  Future<void> _launchCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse('tel:$clean');
    try {
      await launchUrl(url);
    } catch (e) {
      debugPrint('Arama başlatılamadı: $e');
    }
  }

  void _confirmCancel(BuildContext context, SalonProvider provider, AppointmentModel app) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('İptal Et', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: const Text('Bu randevu talebini iptal etmek istediğinize emin misiniz? Bu işlem geri alınamaz.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                provider.updateAppointment(app.copyWith(status: 'iptal'));
                Navigator.pop(context);
              },
              child: const Text('Evet, İptal Et', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SO Yılmaz Berber'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: Consumer<SalonProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final barbers = provider.barbers;

          if (barbers.isEmpty) {
            return const Center(child: Text('Aktif berber bulunamadı.'));
          }

          final myAppointments = _customerId == null
              ? <AppointmentModel>[]
              : provider.appointments.where((a) => a.customerId == _customerId).toList()
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Randevu almak istediğiniz berberi seçin',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Barber Selection Vertical List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: barbers.map((barber) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomerBookingScreen(barber: barber),
                                ),
                              );
                              _loadCustomerId();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.white12,
                                    backgroundImage: barber.profilePicturePath != null
                                        ? (barber.profilePicturePath!.startsWith('http')
                                            ? NetworkImage(barber.profilePicturePath!) as ImageProvider
                                            : FileImage(File(barber.profilePicturePath!)))
                                        : null,
                                    child: barber.profilePicturePath == null
                                        ? const Icon(Icons.person, size: 26, color: Colors.amber)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          barber.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Randevu Al ➔',
                                          style: TextStyle(
                                            color: Colors.amber,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => _launchWhatsApp(barber.phone),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.chat_bubble, color: Colors.green, size: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      InkWell(
                                        onTap: () => _launchCall(barber.phone),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.phone, color: Colors.blue, size: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 24, color: Colors.white10),
                // Randevu Taleplerim Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Randevu Taleplerim',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (myAppointments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 40, color: Colors.grey[800]),
                              const SizedBox(height: 10),
                              Text(
                                'Henüz bir randevu talebiniz bulunmuyor.',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        ...myAppointments.map((app) {
                          final barber = barbers.firstWhere(
                            (b) => b.id == app.barberId,
                            orElse: () => Barber(id: '', name: 'Bilinmiyor', phone: ''),
                          );

                          String statusText = '';
                          Color statusColor = Colors.grey;
                          Widget? actions;

                          if (app.status == 'bekliyor') {
                            statusText = 'Onay Bekliyor';
                            statusColor = Colors.amber;
                            actions = TextButton.icon(
                              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 14),
                              label: const Text('Talebi İptal Et', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                              onPressed: () => _confirmCancel(context, provider, app),
                            );
                          } else if (app.status == 'saat_onerildi') {
                            statusText = 'Yeni Saat Önerildi';
                            statusColor = Colors.orange;
                            actions = Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => provider.updateAppointment(app.copyWith(status: 'iptal')),
                                  child: const Text('Reddet', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  ),
                                  onPressed: () {
                                    final updated = app.copyWith(status: 'onaylandı');
                                    provider.updateAppointment(updated);
                                  },
                                  child: const Text('Kabul Et', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            );
                          } else if (app.status == 'onaylandı') {
                            statusText = 'Onaylandı';
                            statusColor = Colors.green;
                            actions = TextButton.icon(
                              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 14),
                              label: const Text('Randevuyu İptal Et', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                              onPressed: () => _confirmCancel(context, provider, app),
                            );
                          } else if (app.status == 'reddedildi') {
                            statusText = 'Talebiniz berber tarafından reddedildi. Lütfen kendisi ile iletişime geçin.';
                            statusColor = Colors.red;
                            actions = TextButton.icon(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 14),
                              label: const Text('Bu Kaydı Sil', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              onPressed: () => provider.deleteAppointment(app.id),
                            );
                          } else if (app.status == 'iptal') {
                            statusText = 'İptal Ettiğiniz Randevu';
                            statusColor = Colors.redAccent;
                            actions = TextButton.icon(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 14),
                              label: const Text('Bu Kaydı Sil', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              onPressed: () => provider.deleteAppointment(app.id),
                            );
                          } else {
                            statusText = app.status;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        app.category,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Berber: ${barber.name}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(app.dateTime),
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                                if (actions != null) ...[
                                  const SizedBox(height: 4),
                                  const Divider(color: Colors.white10),
                                  actions,
                                ]
                              ],
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
