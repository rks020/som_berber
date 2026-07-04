import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../models/barber.dart';
import '../providers/salon_provider.dart';
import '../theme/app_theme.dart';

class BarbersScreen extends StatelessWidget {
  const BarbersScreen({super.key});

  Future<void> _makeCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Arama yapılamadı: $e');
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, String name) async {
    // Standardize phone for whatsapp: strip spaces, strip leading 0, prepend +90 for Turkey
    var cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = cleanPhone.substring(1);
    }
    if (!cleanPhone.startsWith('+')) {
      cleanPhone = '+90$cleanPhone';
    }
    final message = Uri.encodeComponent('Merhaba $name, hayırlı işler.');
    
    // First try the app scheme directly
    final Uri appUrl = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$message');
    final Uri webUrl = Uri.parse('https://wa.me/$cleanPhone?text=$message');
    
    try {
      await launchUrl(appUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('WhatsApp açılamadı: $e');
      }
    }
  }

  void _showAddBarberDialog(BuildContext context) {
    final provider = Provider.of<SalonProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    String name = '';
    String phone = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text(
            'Yeni Berber Ekle',
            style: TextStyle(
              color: AppTheme.goldPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Berber Ad Soyad',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen ad soyad girin';
                    }
                    return null;
                  },
                  onSaved: (value) => name = value?.trim() ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Telefon Numarası',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '05xx xxx xx xx',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen telefon numarası girin';
                    }
                    return null;
                  },
                  onSaved: (value) => phone = value?.trim() ?? '',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'İptal',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  final id = name
                      .toLowerCase()
                      .replaceAll(RegExp(r'\s+'), '_')
                      .replaceAll(RegExp(r'[^a-z0-9_]'), '');
                  final newBarber = Barber(
                    id: id.isEmpty
                        ? DateTime.now().millisecondsSinceEpoch.toString()
                        : id,
                    name: name,
                    phone: phone,
                  );
                  await provider.addBarber(newBarber);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name berber listesine eklendi'),
                        backgroundColor: AppTheme.goldDark,
                      ),
                    );
                  }
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  void _showEditBarberDialog(BuildContext context, Barber barber) {
    final provider = Provider.of<SalonProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    String name = barber.name;
    String phone = barber.phone;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text(
            'Berberi Düzenle',
            style: TextStyle(
              color: AppTheme.goldPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(
                    labelText: 'Berber Ad Soyad',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen ad soyad girin';
                    }
                    return null;
                  },
                  onSaved: (value) => name = value?.trim() ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon Numarası',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen telefon numarası girin';
                    }
                    return null;
                  },
                  onSaved: (value) => phone = value?.trim() ?? '',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'İptal',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  final updatedBarber = barber.copyWith(
                    name: name,
                    phone: phone,
                  );
                  await provider.updateBarber(updatedBarber);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Berber güncellendi'),
                        backgroundColor: AppTheme.goldDark,
                      ),
                    );
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteBarber(BuildContext context, Barber barber) {
    final provider = Provider.of<SalonProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text('Berberi Sil'),
          content: Text(
            '${barber.name} berberini silmek istediğinize emin misiniz? Bu işlem geçmiş adisyon kayıtlarını etkilemez.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'İptal',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
              ),
              onPressed: () async {
                await provider.deleteBarber(barber.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${barber.name} silindi'),
                      backgroundColor: AppTheme.accentRed,
                    ),
                  );
                }
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickBarberPhoto(BuildContext context, Barber barber) async {
    final ImagePicker picker = ImagePicker();
    // Ask user whether to use camera or gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Fotoğraf Ekle'),
        content: const Text('Fotoğrafı nereden eklemek istersiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Text(
              'Kamera',
              style: TextStyle(color: AppTheme.goldPrimary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Text(
              'Galeri',
              style: TextStyle(color: AppTheme.goldPrimary),
            ),
          ),
        ],
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        final updatedBarber = barber.copyWith(profilePicturePath: image.path);
        await Provider.of<SalonProvider>(
          context,
          listen: false,
        ).updateBarber(updatedBarber);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berber fotoğrafı güncellendi'),
              backgroundColor: AppTheme.goldDark,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalonProvider>(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('PERSONELLER')),
      body: provider.barbers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text(
                    'Berber listesi boş.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddBarberDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Berber Ekle'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: provider.barbers.length,
              itemBuilder: (context, index) {
                final barber = provider.barbers[index];

                // Calculate Barber specific stats (Last 30 Days)
                final now = DateTime.now();
                final start = now.subtract(const Duration(days: 30));

                final barberVisits = provider.visits
                    .where(
                      (v) =>
                          v.barberId == barber.id &&
                          v.status == 'Tamamlandı' &&
                          v.dateTime.isAfter(start),
                    )
                    .toList();

                final double totalRevenue = barberVisits.fold(
                  0.0,
                  (sum, v) => sum + v.totalPrice,
                );
                final int servicesCount = barberVisits.fold(
                  0,
                  (sum, v) => sum + (v.serviceNames.isNotEmpty ? v.serviceNames.length : 1),
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.goldPrimary,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppTheme.goldDark
                                        .withOpacity(0.2),
                                    backgroundImage:
                                        barber.profilePicturePath != null
                                        ? (barber.profilePicturePath!.startsWith('http')
                                            ? NetworkImage(barber.profilePicturePath!) as ImageProvider
                                            : FileImage(File(barber.profilePicturePath!)))
                                        : null,
                                    child: barber.profilePicturePath == null
                                        ? Text(
                                            barber.name.isNotEmpty
                                                ? barber.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: AppTheme.goldPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                InkWell(
                                  onTap: () =>
                                      _pickBarberPhoto(context, barber),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.goldPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: AppTheme.bgDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    barber.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                  Text(
                                    barber.phone,
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: AppTheme.textMuted,
                              ),
                              color: AppTheme.bgCard,
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _showEditBarberDialog(context, barber);
                                } else if (action == 'delete') {
                                  _confirmDeleteBarber(context, barber);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: AppTheme.goldMedium,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Düzenle'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: AppTheme.accentRed,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Sil',
                                        style: TextStyle(
                                          color: AppTheme.accentRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF2C2C2C), height: 24),

                        // Stats (Last 30 Days)
                        const Text(
                          'Son 30 Günlük Performans',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.goldMedium,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPerformaceBox(
                                'İşlem Sayısı',
                                '$servicesCount adet',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildPerformaceBox(
                                'Kazanılan Ciro',
                                currencyFormat.format(totalRevenue),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _makeCall(barber.phone),
                                icon: const Icon(Icons.phone, size: 16),
                                label: const Text(
                                  'Ara',
                                  style: TextStyle(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _openWhatsApp(barber.phone, barber.name),
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 16,
                                ),
                                label: const Text(
                                  'WhatsApp',
                                  style: TextStyle(fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBarberDialog(context),
        tooltip: 'Berber Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPerformaceBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
