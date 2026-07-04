import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../providers/salon_provider.dart';
import '../theme/app_theme.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCustomerDialog(BuildContext context) {
    final provider = Provider.of<SalonProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    String name = '';
    String phone = '';
    String notes = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text(
            'Yeni Müşteri Ekle',
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
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Müşteri Notu / Saç Tercihi',
                      prefixIcon: Icon(Icons.note),
                      hintText: 'Örn: Yanlar 3 numara, sakal makine',
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
                  final newCustomer = Customer(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    phone: phone,
                    notes: notes,
                    createdAt: DateTime.now(),
                  );
                  try {
                    await provider.addCustomer(newCustomer);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$name eklendi'),
                          backgroundColor: AppTheme.goldDark,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hata: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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

  Future<void> _makeCall(String phoneNumber) async {
    // Standardize phone number for call
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Arama yapılamadı: $cleanPhone');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalonProvider>(context);

    // Filter customers based on search query
    final filteredCustomers = provider.customers.where((customer) {
      final q = _searchQuery.toLowerCase();
      return customer.name.toLowerCase().contains(q) ||
          customer.phone.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('MÜŞTERİLER')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Müşteri adı veya telefon numarası ara...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.goldMedium,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppTheme.goldMedium,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Customer List
          Expanded(
            child: filteredCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Kayıtlı müşteri bulunamadı.'
                              : 'Aramanızla eşleşen müşteri bulunamadı.',
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      final initials = customer.name.isNotEmpty
                          ? customer.name
                                .split(' ')
                                .map((e) => e[0])
                                .take(2)
                                .join('')
                                .toUpperCase()
                          : '?';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CustomerDetailScreen(customer: customer),
                              ),
                            );
                          },
                          leading: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.goldPrimary,
                                width: 1,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: AppTheme.goldDark.withOpacity(
                                0.2,
                              ),
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: AppTheme.goldPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textLight,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                customer.phone,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              if (customer.notes.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  customer.notes,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.goldMedium,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.phone,
                                  color: AppTheme.goldPrimary,
                                ),
                                onPressed: () => _makeCall(customer.phone),
                                tooltip: 'Ara',
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppTheme.textMuted,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context),
        tooltip: 'Müşteri Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }
}
