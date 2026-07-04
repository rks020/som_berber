import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/visit.dart';
import '../models/barber.dart';
import '../theme/app_theme.dart';
import '../providers/salon_provider.dart';
import '../screens/visit_entry_screen.dart';

class VisitCard extends StatelessWidget {
  final Visit visit;
  final VoidCallback? onTap;

  const VisitCard({super.key, required this.visit, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );
    final provider = Provider.of<SalonProvider>(context, listen: false);

    // Get barber name
    final barberName = provider.barbers
        .firstWhere(
          (b) => b.id == visit.barberId,
          orElse: () => Barber(id: '', name: 'Bilinmeyen Berber', phone: ''),
        )
        .name;

    // Payment badge color
    Color badgeColor;
    Color textColor;
    switch (visit.paymentMethod) {
      case 'Nakit':
        badgeColor = const Color(0xFF1E3A1E);
        textColor = const Color(0xFF81C784);
        break;
      case 'Kart':
        badgeColor = const Color(0xFF1B365D);
        textColor = const Color(0xFF64B5F6);
        break;
      case 'Veresiye':
        badgeColor = const Color(0xFF422222);
        textColor = const Color(0xFFE57373);
        break;
      default:
        badgeColor = Colors.grey.shade900;
        textColor = Colors.grey.shade400;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Customer Name and Total Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      visit.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                  Text(
                    currencyFormat.format(visit.totalPrice),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 20,
                      color: AppTheme.goldMedium,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VisitEntryScreen(existingVisit: visit),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Row 2: Date and Time
              Text(
                dateFormat.format(visit.dateTime),
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const Divider(color: Color(0xFF2C2C2C), height: 16),

              // Row 3: Services (List of names)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: visit.serviceNames.map((sName) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      sName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.goldMedium,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Row 4: Barber and Payment Method
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Barber Info
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 14,
                        color: AppTheme.goldMedium,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        barberName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),

                  // Payment Method Badge
                  Row(
                    children: [
                      if (visit.status == 'Randevu') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3E2D00),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Randevu',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          visit.paymentMethod,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (visit.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.03)),
                  ),
                  child: Text(
                    'Not: ${visit.notes}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
