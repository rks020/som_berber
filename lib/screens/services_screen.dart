import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/service.dart';
import '../providers/salon_provider.dart';
import '../theme/app_theme.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  void _showAddServiceDialog(BuildContext context) {
    final provider = Provider.of<SalonProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    String name = '';
    double price = 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text(
            'Yeni Hizmet Ekle',
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
                    labelText: 'Hizmet Adı',
                    prefixIcon: Icon(Icons.dry_cleaning),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen hizmet adı girin';
                    }
                    return null;
                  },
                  onSaved: (value) => name = value?.trim() ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Fiyat (₺)',
                    prefixIcon: Icon(Icons.payments),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen fiyat girin';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Geçerli bir sayı girin';
                    }
                    return null;
                  },
                  onSaved: (value) =>
                      price = double.tryParse(value ?? '0') ?? 0.0,
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
                  // Create a unique id by slugifying name or using timestamp
                  final id = name
                      .toLowerCase()
                      .replaceAll(RegExp(r'\s+'), '_')
                      .replaceAll(RegExp(r'[^a-z0-9_]'), '');
                  final newService = Service(
                    id: id.isEmpty
                        ? DateTime.now().millisecondsSinceEpoch.toString()
                        : id,
                    name: name,
                    price: price,
                  );
                  await provider.addService(newService);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name hizmet listesine eklendi'),
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

  void _showEditServiceDialog(BuildContext context, Service service) {
    final provider = Provider.of<SalonProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    String name = service.name;
    double price = service.price;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text(
            'Hizmeti Düzenle',
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
                    labelText: 'Hizmet Adı',
                    prefixIcon: Icon(Icons.dry_cleaning),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen hizmet adı girin';
                    }
                    return null;
                  },
                  onSaved: (value) => name = value?.trim() ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: price.toStringAsFixed(0),
                  decoration: const InputDecoration(
                    labelText: 'Fiyat (₺)',
                    prefixIcon: Icon(Icons.payments),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen fiyat girin';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Geçerli bir sayı girin';
                    }
                    return null;
                  },
                  onSaved: (value) =>
                      price = double.tryParse(value ?? '0') ?? 0.0,
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
                  final updatedService = service.copyWith(
                    name: name,
                    price: price,
                  );
                  await provider.updateService(updatedService);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hizmet güncellendi'),
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

  void _confirmDeleteService(BuildContext context, Service service) {
    final provider = Provider.of<SalonProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text('Hizmeti Sil'),
          content: Text(
            '${service.name} hizmetini fiyat listesinden silmek istediğinize emin misiniz? Bu işlem geçmiş adisyonları etkilemez.',
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
                await provider.deleteService(service.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${service.name} silindi'),
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalonProvider>(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('FİYAT LİSTESİ')),
      body: provider.services.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.dry_cleaning,
                    size: 64,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Fiyat listesi boş.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddServiceDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Hizmet Ekle'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: provider.services.length,
              itemBuilder: (context, index) {
                final service = provider.services[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.black12,
                      child: Icon(
                        Icons.cut_outlined,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    title: Text(
                      service.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currencyFormat.format(service.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppTheme.textMuted,
                          ),
                          color: AppTheme.bgCard,
                          onSelected: (action) {
                            if (action == 'edit') {
                              _showEditServiceDialog(context, service);
                            } else if (action == 'delete') {
                              _confirmDeleteService(context, service);
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
                                    style: TextStyle(color: AppTheme.accentRed),
                                  ),
                                ],
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
        onPressed: () => _showAddServiceDialog(context),
        tooltip: 'Hizmet Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }
}
