import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../models/customer.dart';
import '../models/barber.dart';
import '../models/visit.dart';
import '../providers/salon_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/visit_card.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Customer _currentCustomer;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
  }

  void _showEditCustomerDialog() {
    final provider = Provider.of<SalonProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    String name = _currentCustomer.name;
    String phone = _currentCustomer.phone;
    String notes = _currentCustomer.notes;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text(
            'Müşteriyi Düzenle',
            style: TextStyle(
              color: AppTheme.goldPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
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
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: notes,
                    decoration: const InputDecoration(
                      labelText: 'Müşteri Notu / Saç Tercihi',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                    onSaved: (value) => notes = value?.trim() ?? '',
                  ),
                ],
              ),
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
                  final updatedCustomer = _currentCustomer.copyWith(
                    name: name,
                    phone: phone,
                    notes: notes,
                  );
                  await provider.updateCustomer(updatedCustomer);
                  setState(() {
                    _currentCustomer = updatedCustomer;
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Müşteri güncellendi'),
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

  void _confirmDelete() {
    final provider = Provider.of<SalonProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text('Müşteriyi Sil'),
          content: Text(
            '${_currentCustomer.name} isimli müşteriyi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
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
                await provider.deleteCustomer(_currentCustomer.id);
                if (mounted) {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // close detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_currentCustomer.name} silindi'),
                      backgroundColor: AppTheme.accentRed,
                    ),
                  );
                }
              },
              child: const Text('Evet, Sil'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _pickProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final updatedCustomer = _currentCustomer.copyWith(
        profilePicturePath: image.path,
      );
      await Provider.of<SalonProvider>(
        context,
        listen: false,
      ).updateCustomer(updatedCustomer);
      setState(() {
        _currentCustomer = updatedCustomer;
      });
    }
  }

  Future<void> _takeVisitPhoto(Visit visit) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final updatedVisit = visit.copyWith(photoPath: image.path);
      await Provider.of<SalonProvider>(
        context,
        listen: false,
      ).updateVisit(updatedVisit);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşlem fotoğrafı eklendi'),
          backgroundColor: AppTheme.goldDark,
        ),
      );
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

    // Get visits for this customer
    final customerVisits = provider.getVisitsForCustomer(_currentCustomer.id);

    // Stats calculations
    final int visitCount = customerVisits.length;
    final double totalSpent = customerVisits.fold(
      0.0,
      (sum, v) => sum + v.totalPrice,
    );

    // Preferred Barber calculation
    String preferredBarber = 'Belirtilmemiş';
    if (customerVisits.isNotEmpty) {
      final Map<String, int> barberCounts = {};
      for (var v in customerVisits) {
        barberCounts[v.barberId] = (barberCounts[v.barberId] ?? 0) + 1;
      }
      var maxCount = 0;
      String preferredBarberId = '';
      barberCounts.forEach((id, count) {
        if (count > maxCount) {
          maxCount = count;
          preferredBarberId = id;
        }
      });
      preferredBarber = provider.barbers
          .firstWhere(
            (b) => b.id == preferredBarberId,
            orElse: () => Barber(id: '', name: 'Bilinmeyen', phone: ''),
          )
          .name;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Müşteri Detayı',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditCustomerDialog,
            tooltip: 'Düzenle',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppTheme.accentRed),
            onPressed: _confirmDelete,
            tooltip: 'Sil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Customer Main Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
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
                            radius: 35,
                            backgroundColor: AppTheme.goldDark.withOpacity(0.2),
                            backgroundImage:
                                _currentCustomer.profilePicturePath != null
                                ? FileImage(
                                    File(_currentCustomer.profilePicturePath!),
                                  )
                                : null,
                            child: _currentCustomer.profilePicturePath == null
                                ? Text(
                                    _currentCustomer.name.isNotEmpty
                                        ? _currentCustomer.name
                                              .split(' ')
                                              .map((e) => e[0])
                                              .take(2)
                                              .join('')
                                              .toUpperCase()
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
                          onTap: _pickProfilePicture,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.goldPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: AppTheme.bgDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentCustomer.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 14,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _currentCustomer.phone,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () => _makeCall(_currentCustomer.phone),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary.withOpacity(0.15),
                        foregroundColor: AppTheme.goldPrimary,
                      ),
                      icon: const Icon(Icons.phone),
                      tooltip: 'Ara',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Preferences / Customer Notes Card
            const Text(
              'Saç / Tarz Tercih Notu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.goldMedium,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentCustomer.notes.isNotEmpty
                          ? _currentCustomer.notes
                          : 'Bu müşteri için özel bir tercih notu eklenmemiş.',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: _currentCustomer.notes.isNotEmpty
                            ? FontStyle.normal
                            : FontStyle.italic,
                        color: _currentCustomer.notes.isNotEmpty
                            ? AppTheme.textLight
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Stats Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Ziyaret Sayısı',
                    '$visitCount',
                    Icons.event,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatItem(
                    'Toplam Ciro',
                    currencyFormat.format(totalSpent),
                    Icons.monetization_on,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildStatItem(
              'Tercih Ettiği Berber',
              preferredBarber,
              Icons.face_retouching_natural,
            ),
            const SizedBox(height: 24),

            // 4. Last Visit Photo
            const Text(
              'Son İşlem Fotoğrafı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final latestVisit = customerVisits.isNotEmpty
                    ? customerVisits.first
                    : null;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (latestVisit?.photoPath != null) ...[
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(latestVisit!.photoPath!),
                                  width: double.infinity,
                                  height: 220,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: AppTheme.bgCard,
                                        title: const Text('Fotoğrafı Sil'),
                                        content: const Text(
                                          'Son işlem fotoğrafı silinsin mi?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text(
                                              'İptal',
                                              style: TextStyle(
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.accentRed,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Sil'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      final updated = latestVisit.copyWith(
                                        photoPath: null,
                                      );
                                      await Provider.of<SalonProvider>(
                                        context,
                                        listen: false,
                                      ).updateVisit(updated);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Fotoğraf silindi'),
                                          backgroundColor: AppTheme.accentRed,
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ] else
                          Container(
                            width: double.infinity,
                            height: 140,
                            decoration: BoxDecoration(
                              color: AppTheme.bgDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_camera,
                                  color: AppTheme.textMuted,
                                  size: 40,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Henüz fotoğraf eklenmedi',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: latestVisit == null
                                    ? null
                                    : () async {
                                        final picker = ImagePicker();
                                        final img = await picker.pickImage(
                                          source: ImageSource.camera,
                                        );
                                        if (img != null) {
                                          final updated = latestVisit.copyWith(
                                            photoPath: img.path,
                                          );
                                          await Provider.of<SalonProvider>(
                                            context,
                                            listen: false,
                                          ).updateVisit(updated);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Fotoğraf eklendi'),
                                              backgroundColor:
                                                  AppTheme.goldDark,
                                            ),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('Kamera'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.goldPrimary,
                                  side: const BorderSide(
                                    color: AppTheme.goldPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: latestVisit == null
                                    ? null
                                    : () async {
                                        final picker = ImagePicker();
                                        final img = await picker.pickImage(
                                          source: ImageSource.gallery,
                                        );
                                        if (img != null) {
                                          final updated = latestVisit.copyWith(
                                            photoPath: img.path,
                                          );
                                          await Provider.of<SalonProvider>(
                                            context,
                                            listen: false,
                                          ).updateVisit(updated);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Fotoğraf eklendi'),
                                              backgroundColor:
                                                  AppTheme.goldDark,
                                            ),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.photo_library, size: 18),
                                label: const Text('Galeri'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.goldMedium,
                                  side: const BorderSide(
                                    color: AppTheme.goldMedium,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (latestVisit == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Fotoğraf eklemek için önce bir işlem kaydedilmeli.',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 5. Visit History
            const Text(
              'Ziyaret Geçmişi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 12),
            if (customerVisits.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222222)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.history, color: AppTheme.textMuted, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Ziyaret geçmişi bulunmuyor.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: customerVisits.length,
                itemBuilder: (context, index) {
                  final visit = customerVisits[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      VisitCard(visit: visit),
                      if (visit.photoPath != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(visit.photoPath!),
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      if (index == 0) // Only for the latest visit
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: OutlinedButton.icon(
                            onPressed: () => _takeVisitPhoto(visit),
                            icon: const Icon(Icons.camera_alt),
                            label: Text(
                              visit.photoPath != null
                                  ? 'Fotoğrafı Değiştir'
                                  : 'Son İşlem İçin Fotoğraf Ekle',
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.goldPrimary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
