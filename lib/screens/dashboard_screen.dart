import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle(
                      'Bugünkü Randevular (${todayAppointments.length})',
                    ),
                    if (todayAppointments.isNotEmpty)
                      const Icon(
                        Icons.calendar_month,
                        color: AppTheme.goldMedium,
                        size: 18,
                      ),
                  ],
                ),
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
                      ));
                    },
                  ),
                const SizedBox(height: 24),

                // 5. Today's visits
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle(
                      'Bugünkü İşlemler (${todayVisits.length})',
                    ),
                    if (todayVisits.isNotEmpty)
                      const Icon(
                        Icons.history_toggle_off,
                        color: AppTheme.goldMedium,
                        size: 18,
                      ),
                  ],
                ),
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
