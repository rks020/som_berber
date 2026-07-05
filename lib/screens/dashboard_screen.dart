import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import 'package:provider/provider.dart';
import '../providers/salon_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_widget.dart';
import '../widgets/visit_card.dart';
import '../models/appointment.dart';
import '../models/visit.dart';
import '../models/barber.dart';
import 'visit_entry_screen.dart';
import 'auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isTodayVisitsExpanded = true;
  bool _isTodayAppointmentsExpanded = true;
  bool _isPendingAppointmentsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalonProvider>(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldPrimary),
      );
    }

    final DateTime now = DateTime.now();
    final double daily = provider.getDailyRevenue(now);
    final double weekly = provider.getWeeklyRevenue(now);
    final double monthly = provider.getMonthlyRevenue(now);

    final paymentMethods = provider.getRevenueByPaymentMethod(
      now.subtract(const Duration(days: 30)),
      now,
    );
    final totalPayment = paymentMethods.values.fold(
      0.0,
      (sum, val) => sum + val,
    );

    final barberShares = provider.getRevenueByBarber(
      now.subtract(const Duration(days: 30)),
      now,
    );
    final totalBarberRevenue = barberShares.values.fold(
      0.0,
      (sum, val) => sum + val,
    );

    final todayVisits = provider.visits.where((v) {
      final vDate = v.dateTime;
      return vDate.year == now.year &&
          vDate.month == now.month &&
          vDate.day == now.day;
    }).toList();

    final todayAppointments = provider.appointments.where((a) {
      if (a.status == 'iptal' || a.status == 'reddedildi') return false;
      final aDate = a.dateTime;
      return aDate.year == now.year &&
          aDate.month == now.month &&
          aDate.day == now.day;
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.goldPrimary,
          backgroundColor: AppTheme.bgCard,
          onRefresh: () => provider.init(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header with Logo & Brand Name
                Row(
                  children: [
                    const BarberLogo(size: 55),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YILMAZ HAIR',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              foreground: Paint()
                                ..shader = AppTheme.goldGradient.createShader(
                                  const Rect.fromLTWH(0, 0, 200, 30),
                                ),
                            ),
                          ),
                          const Text(
                            'Premium Berber Salonu',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quick Visit Entry Button
                    IconButton.filled(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VisitEntryScreen(),
                          ),
                        );
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: AppTheme.bgDark,
                      ),
                      icon: const Icon(Icons.add),
                      tooltip: 'Yeni Adisyon Ekle',
                    ),
                    const SizedBox(width: 8),
                    // Logout Button
                    IconButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('is_admin_logged_in');
                        await prefs.remove('admin_selected_barber_id');
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthScreen()),
                          );
                        }
                      },
                      icon: const Icon(Icons.logout, color: AppTheme.accentRed),
                      tooltip: 'Çıkış Yap',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Income Cards (Grid/Scrollable row)
                const Text(
                  'Gelir Özeti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldMedium,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildRevenueCard(
                        title: 'Bugün',
                        amount: daily,
                        currencyFormat: currencyFormat,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildRevenueCard(
                        title: 'Bu Hafta',
                        amount: weekly,
                        currencyFormat: currencyFormat,
                        color: AppTheme.goldMedium,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildRevenueCard(
                        title: 'Bu Ay',
                        amount: monthly,
                        currencyFormat: currencyFormat,
                        color: AppTheme.goldLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. Financial breakdowns & Barber Shares in a side-by-side or stacked view
                _buildSectionTitle('Ödeme Yöntemleri Dağılımı (Son 30 Gün)'),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildPaymentMethodRow(
                          'Nakit',
                          paymentMethods['Nakit'] ?? 0.0,
                          totalPayment,
                          currencyFormat,
                          const Color(0xFF81C784),
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentMethodRow(
                          'Kart',
                          paymentMethods['Kart'] ?? 0.0,
                          totalPayment,
                          currencyFormat,
                          const Color(0xFF64B5F6),
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentMethodRow(
                          'Veresiye',
                          paymentMethods['Veresiye'] ?? 0.0,
                          totalPayment,
                          currencyFormat,
                          const Color(0xFFE57373),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Berber Ciroları (Son 30 Gün)'),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: barberShares.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildBarberShareRow(
                            entry.key,
                            entry.value,
                            totalBarberRevenue,
                            currencyFormat,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Today's Appointments
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isTodayAppointmentsExpanded = !_isTodayAppointmentsExpanded;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(
                        'Bugünkü Randevular (${todayAppointments.length})',
                      ),
                      Icon(
                        _isTodayAppointmentsExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.goldMedium,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                if (_isTodayAppointmentsExpanded) ...[
                  const SizedBox(height: 12),
                  if (todayAppointments.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF222222)),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey,
                            size: 40,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Bugün için randevu bulunmuyor.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: todayAppointments.length > 5
                          ? 5
                          : todayAppointments.length,
                      itemBuilder: (context, index) {
                        final appt = todayAppointments[index];
                        return GestureDetector(
                          onTap: () => _showCompleteAppointmentSheet(context, appt),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(
                                        'FF${appt.colorHex.replaceAll('#', '')}',
                                        radix: 16,
                                      ),
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: appt.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' (${provider.barbers.firstWhere((b) => b.id == appt.barberId, orElse: () => Barber(id: '', name: 'Bilinmiyor', phone: '')).name})',
                                              style: const TextStyle(
                                                color: AppTheme.goldMedium,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        appt.category,
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      DateFormat('HH:mm').format(appt.dateTime),
                                      style: const TextStyle(
                                        color: AppTheme.goldPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${appt.durationMinutes} dk',
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
                const SizedBox(height: 24),

                // 5. Today's visits
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isTodayVisitsExpanded = !_isTodayVisitsExpanded;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(
                        'Bugünkü İşlemler (${todayVisits.length})',
                      ),
                      Icon(
                        _isTodayVisitsExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.goldMedium,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                if (_isTodayVisitsExpanded) ...[
                  const SizedBox(height: 12),
                  if (todayVisits.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF222222)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.content_cut, color: Colors.grey, size: 40),
                          SizedBox(height: 10),
                          Text(
                            'Bugün henüz bir işlem girilmemiş.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: todayVisits.length > 5 ? 5 : todayVisits.length,
                      itemBuilder: (context, index) {
                        return VisitCard(visit: todayVisits[index]);
                      },
                    ),
                ],
                                // 6. Pending Appointments
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPendingAppointmentsExpanded = !_isPendingAppointmentsExpanded;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(
                        'Randevu Talepleri (${provider.appointments.where((a) => ['bekliyor', 'saat_onerildi', 'onaylandı', 'iptal', 'reddedildi'].contains(a.status) && !a.isDismissedFromRequests).length})',
                      ),
                      Icon(
                        _isPendingAppointmentsExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.goldMedium,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                if (_isPendingAppointmentsExpanded) ...[
                  const SizedBox(height: 12),
                  (() {
                    final pendingApps = provider.appointments.where((a) => ['bekliyor', 'saat_onerildi', 'onaylandı', 'iptal', 'reddedildi'].contains(a.status) && !a.isDismissedFromRequests).toList();
                    if (pendingApps.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF222222)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.hourglass_empty, color: Colors.grey, size: 40),
                            SizedBox(height: 10),
                            Text(
                              'Bekleyen randevu talebi bulunmuyor.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pendingApps.length,
                      itemBuilder: (context, index) {
                        final appt = pendingApps[index];
                        final barberName = provider.barbers.firstWhere(
                          (b) => b.id == appt.barberId,
                          orElse: () => Barber(id: '', name: 'Bilinmiyor', phone: ''),
                        ).name;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          appt.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        if (appt.status == 'onaylandı' || appt.status == 'iptal' || appt.status == 'reddedildi')
                                          InkWell(
                                            onTap: () async {
                                              await provider.updateAppointment(appt.copyWith(isDismissedFromRequests: true));
                                            },
                                            child: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${appt.category}  •  Berber: $barberName',
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(appt.dateTime),
                                      style: const TextStyle(color: AppTheme.goldMedium, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              appt.status == 'saat_onerildi'
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.orange),
                                      ),
                                      child: const Text('Müşteri Yanıtı Bekleniyor', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                    )
                                  : appt.status == 'onaylandı'
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.green),
                                          ),
                                          child: const Text('Onaylandı', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                        )
                                      : (appt.status == 'iptal' || appt.status == 'reddedildi')
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.red),
                                              ),
                                              child: Text(appt.status == 'iptal' ? 'Müşteri İptal Etti' : 'Reddedildi', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                            )
                                          : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          onPressed: () => provider.updateAppointment(appt.copyWith(status: 'reddedildi')),
                                          tooltip: 'Reddet',
                                        ),
                                  IconButton(
                                    icon: const Icon(Icons.more_time, color: Colors.orange),
                                    onPressed: () async {
                                      final selectedDate = await showDatePicker(
                                        context: context,
                                        initialDate: appt.dateTime,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                        locale: const Locale('tr', 'TR'),
                                      );
                                      if (selectedDate == null) return;

                                      if (!context.mounted) return;
                                      final selectedTime = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(appt.dateTime),
                                      );
                                      if (selectedTime == null) return;

                                      final newDateTime = DateTime(
                                        selectedDate.year,
                                        selectedDate.month,
                                        selectedDate.day,
                                        selectedTime.hour,
                                        selectedTime.minute,
                                      );

                                      final updated = appt.copyWith(
                                        dateTime: newDateTime,
                                        status: 'saat_onerildi',
                                      );
                                      provider.updateAppointment(updated);
                                    },
                                    tooltip: 'Yeni Saat Öner',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () async {
                                        final approved = appt.copyWith(status: 'onaylandı');
                                        await provider.updateAppointment(approved);
                                      },
                                      tooltip: 'Onayla',
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          (() {
                            final customer = provider.customers.firstWhere((c) => c.id == appt.customerId, orElse: () => Customer(id: '', name: '', phone: '', createdAt: DateTime.now()));
                            if (customer.phone.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final url = Uri.parse('tel:${customer.phone}');
                                      if (await canLaunchUrl(url)) await launchUrl(url);
                                    },
                                    icon: const Icon(Icons.phone, size: 16),
                                    label: const Text('Ara'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF333333),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final clean = customer.phone.replaceAll(RegExp(r'\D'), '');
                                      final finalPhone = clean.startsWith('90') ? clean : (clean.startsWith('0') ? '9$clean' : '90$clean');
                                      final url = Uri.parse('https://wa.me/$finalPhone');
                                      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                                    },
                                    icon: const Icon(Icons.chat, size: 16),
                                    label: const Text('WhatsApp'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })(),
                        ],
                      ),
                    );
                  },
                    );
                  })(),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textLight,
      ),
    );
  }

  void _showCompleteAppointmentSheet(BuildContext context, AppointmentModel appt) {
    final provider = Provider.of<SalonProvider>(context, listen: false);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    String selectedPayment = 'Nakit';
    final priceController = TextEditingController(
      text: appt.price > 0 ? appt.price.toStringAsFixed(0) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Color(int.parse('FF${appt.colorHex.replaceAll('#', '')}', radix: 16)),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${appt.title} (${provider.barbers.firstWhere((b) => b.id == appt.barberId, orElse: () => Barber(id: '', name: 'Bilinmiyor', phone: '')).name})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${appt.category}  •  ${DateFormat('HH:mm').format(appt.dateTime)}  •  ${appt.durationMinutes} dk',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  if (appt.additionalPeople.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Kişiler: ${appt.additionalPeople}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ],
                  const Divider(color: Colors.white12, height: 28),

                  // Price field
                  const Text('Alınan Ücret (TL)', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Fiyat'),
                  ),
                  const SizedBox(height: 20),

                  // Payment method
                  const Text('Ödeme Yöntemi', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: ['Nakit', 'Kart', 'Veresiye'].map((method) {
                      final isSelected = selectedPayment == method;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedPayment = method),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.goldPrimary : AppTheme.bgDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSelected ? AppTheme.goldPrimary : Colors.white12),
                            ),
                            child: Center(
                              child: Text(
                                method,
                                style: TextStyle(
                                  color: isSelected ? AppTheme.bgDark : AppTheme.textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Complete button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final price = double.tryParse(priceController.text.trim()) ?? appt.price;

                        final visit = Visit(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          customerId: appt.customerId ?? '',
                          customerName: appt.title,
                          barberId: appt.barberId ?? '',
                          serviceIds: const [],
                          serviceNames: [appt.category],
                          servicePrices: [price],
                          totalPrice: price,
                          paymentMethod: selectedPayment,
                          dateTime: appt.dateTime,
                          notes: appt.additionalPeople.isNotEmpty ? 'Kişiler: ${appt.additionalPeople}' : '',
                          status: 'Tamamlandı',
                        );

                        provider.addVisit(visit);
                        provider.deleteAppointment(appt.id);
                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${appt.title} işlemi tamamlandı! ${currencyFormat.format(price)} ($selectedPayment)'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Tamamlandı Olarak İşle', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: AppTheme.bgDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRevenueCard({
    required String title,
    required double amount,
    required NumberFormat currencyFormat,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        gradient: LinearGradient(
          colors: [AppTheme.bgCard, color.withOpacity(0.04)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow(
    String label,
    double amount,
    double total,
    NumberFormat format,
    Color color,
  ) {
    final double percent = total > 0 ? (amount / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textLight,
              ),
            ),
            Text(
              '${format.format(amount)} (${(percent * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildBarberShareRow(
    String name,
    double amount,
    double total,
    NumberFormat format,
  ) {
    final double percent = total > 0 ? (amount / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textLight,
              ),
            ),
            Text(
              '${format.format(amount)} (${(percent * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.goldPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.goldPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
