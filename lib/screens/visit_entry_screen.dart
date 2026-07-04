import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/visit.dart';
import '../providers/salon_provider.dart';
import '../theme/app_theme.dart';

class VisitEntryScreen extends StatefulWidget {
  final Customer? preselectedCustomer;
  final Visit? existingVisit;

  const VisitEntryScreen({
    super.key,
    this.preselectedCustomer,
    this.existingVisit,
  });

  @override
  State<VisitEntryScreen> createState() => _VisitEntryScreenState();
}

class _VisitEntryScreenState extends State<VisitEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customCustomerController = TextEditingController();
  final _priceOverrideController = TextEditingController();
  final _notesController = TextEditingController();

  Customer? _selectedCustomer;
  bool _isQuickCustomer = false;
  String _quickCustomerName = 'Misafir Müşteri';

  String _selectedBarberId = '';
  final Set<String> _selectedServiceIds = {};

  double _calculatedTotal = 0.0;
  bool _isPriceOverridden = false;

  String _paymentMethod = 'Nakit'; // Nakit, Kart, Veresiye
  String _status = 'Tamamlandı'; // Tamamlandı, Randevu

  DateTime _selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SalonProvider>(context, listen: false);

    if (widget.existingVisit != null) {
      final v = widget.existingVisit!;
      _selectedBarberId = v.barberId;
      _selectedServiceIds.addAll(v.serviceIds);
      _status = v.status;
      _paymentMethod = v.paymentMethod;
      _selectedDateTime = v.dateTime;
      _priceOverrideController.text = v.totalPrice.toStringAsFixed(0);
      _notesController.text = v.notes;
      _isPriceOverridden = true;
      _calculatedTotal = v.totalPrice;

      if (v.customerId == 'quick_customer') {
        _isQuickCustomer = true;
        _customCustomerController.text = v.customerName;
      } else {
        _isQuickCustomer = false;
        try {
          _selectedCustomer = provider.customers.firstWhere(
            (c) => c.id == v.customerId,
          );
        } catch (e) {
          _selectedCustomer = null;
        }
      }
    } else {
      // Default barber to first one if available
      if (provider.barbers.isNotEmpty) {
        _selectedBarberId = provider.barbers.first.id;
      }

      if (widget.preselectedCustomer != null) {
        _selectedCustomer = widget.preselectedCustomer;
      } else {
        _isQuickCustomer = true;
        _customCustomerController.text = 'Misafir Müşteri';
      }
    }
  }

  @override
  void dispose() {
    _customCustomerController.dispose();
    _priceOverrideController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateTotal(SalonProvider provider) {
    double total = 0.0;
    for (var id in _selectedServiceIds) {
      final s = provider.services.firstWhere(
        (element) => element.id == id,
        orElse: () => provider.services.first,
      );
      total += s.price;
    }
    setState(() {
      _calculatedTotal = total;
      if (!_isPriceOverridden) {
        _priceOverrideController.text = total.toStringAsFixed(0);
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.goldPrimary,
              onPrimary: AppTheme.bgDark,
              surface: AppTheme.bgCard,
              onSurface: AppTheme.textLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.goldPrimary,
                onPrimary: AppTheme.bgDark,
                surface: AppTheme.bgCard,
                onSurface: AppTheme.textLight,
              ),
            ),
            child: child!,
          );
        },
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveVisit(SalonProvider provider) async {
    if (_selectedBarberId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen işlem yapan berberi seçin'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    if (_selectedServiceIds.isEmpty && _status == 'Tamamlandı') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir hizmet seçin'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    String customerId;
    String customerName;

    if (_isQuickCustomer) {
      customerId = 'quick_customer';
      customerName = _customCustomerController.text.trim();
      if (customerName.isEmpty) {
        customerName = 'Misafir Müşteri';
      }
    } else {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen müşteri seçin'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
        return;
      }
      customerId = _selectedCustomer!.id;
      customerName = _selectedCustomer!.name;
    }

    // Collect snapshots of selected services
    final List<String> sIds = [];
    final List<String> sNames = [];
    final List<double> sPrices = [];

    for (var id in _selectedServiceIds) {
      final s = provider.services.firstWhere((element) => element.id == id);
      sIds.add(s.id);
      sNames.add(s.name);
      sPrices.add(s.price);
    }

    final double finalPrice =
        double.tryParse(_priceOverrideController.text) ?? _calculatedTotal;

    final newVisit = Visit(
      id:
          widget.existingVisit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: customerId,
      customerName: customerName,
      barberId: _selectedBarberId,
      serviceIds: sIds,
      serviceNames: sNames,
      servicePrices: sPrices,
      totalPrice: finalPrice,
      paymentMethod: _paymentMethod,
      dateTime: _selectedDateTime,
      notes: _notesController.text.trim(),
      status: _status,
      photoPath: widget.existingVisit?.photoPath,
    );

    if (widget.existingVisit != null) {
      await provider.updateVisit(newVisit);
    } else {
      await provider.addVisit(newVisit);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$customerName işlemi başarıyla ${widget.existingVisit != null ? 'güncellendi' : 'kaydedildi'}.',
          ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingVisit != null ? 'İŞLEMİ DÜZENLE' : 'YENİ İŞLEM GİRİŞİ',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Customer Selection Box
              const Text(
                'Müşteri Bilgisi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldMedium,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Choice between registered and quick customer
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Kayıtlı Müşteri'),
                              selected: !_isQuickCustomer,
                              onSelected: (selected) {
                                setState(() {
                                  _isQuickCustomer = !selected;
                                  if (selected &&
                                      _selectedCustomer == null &&
                                      provider.customers.isNotEmpty) {
                                    _selectedCustomer =
                                        provider.customers.first;
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Misafir / Hızlı'),
                              selected: _isQuickCustomer,
                              onSelected: (selected) {
                                setState(() {
                                  _isQuickCustomer = selected;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isQuickCustomer)
                        TextFormField(
                          controller: _customCustomerController,
                          decoration: const InputDecoration(
                            labelText: 'Müşteri Adı (Opsiyonel)',
                            prefixIcon: Icon(Icons.person_outline),
                            hintText: 'Örn: Ahmet Y.',
                          ),
                          textCapitalization: TextCapitalization.words,
                        )
                      else
                        DropdownButtonFormField<Customer>(
                          value: _selectedCustomer,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 16,
                          ),
                          dropdownColor: AppTheme.bgCard,
                          decoration: const InputDecoration(
                            labelText: 'Müşteri Seçin',
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: provider.customers.map((c) {
                            return DropdownMenuItem<Customer>(
                              value: c,
                              child: Text(c.name),
                            );
                          }).toList(),
                          onChanged: (customer) {
                            setState(() {
                              _selectedCustomer = customer;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Barber Selection Box
              const Text(
                'İşlemi Yapan Berber',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldMedium,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: provider.barbers.map((barber) {
                      return RadioListTile<String>(
                        title: Text(
                          barber.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                        ),
                        subtitle: Text(
                          barber.phone,
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                        value: barber.id,
                        groupValue: _selectedBarberId,
                        activeColor: AppTheme.goldPrimary,
                        onChanged: (value) {
                          setState(() {
                            _selectedBarberId = value ?? '';
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Services Selection Box
              const Text(
                'Uygulanan Hizmetler',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldMedium,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.services.length,
                    itemBuilder: (context, index) {
                      final service = provider.services[index];
                      final isSelected = _selectedServiceIds.contains(
                        service.id,
                      );
                      return CheckboxListTile(
                        title: Text(
                          service.name,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        secondary: Text(
                          currencyFormat.format(service.price),
                          style: const TextStyle(
                            color: AppTheme.goldPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: isSelected,
                        activeColor: AppTheme.goldPrimary,
                        checkColor: AppTheme.bgDark,
                        onChanged: (selected) {
                          setState(() {
                            if (selected ?? false) {
                              _selectedServiceIds.add(service.id);
                            } else {
                              _selectedServiceIds.remove(service.id);
                            }
                            _calculateTotal(provider);
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Details (Date, Status, Payment, Price Override)
              const Text(
                'İşlem ve Ödeme Detayı',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldMedium,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Segment
                      const Text(
                        'İşlem Durumu',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Tamamlandı'),
                              selected: _status == 'Tamamlandı',
                              onSelected: (selected) {
                                if (selected)
                                  setState(() => _status = 'Tamamlandı');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Randevu'),
                              selected: _status == 'Randevu',
                              onSelected: (selected) {
                                if (selected)
                                  setState(() => _status = 'Randevu');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Payment Method
                      const Text(
                        'Ödeme Yöntemi',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: ['Nakit', 'Kart', 'Veresiye'].map((method) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: ChoiceChip(
                              label: Text(method),
                              selected: _paymentMethod == method,
                              onSelected: (selected) {
                                if (selected)
                                  setState(() => _paymentMethod = method);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Date Time selector
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Tarih / Saat',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat(
                            'dd.MM.yyyy - HH:mm',
                          ).format(_selectedDateTime),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.calendar_today,
                            color: AppTheme.goldPrimary,
                          ),
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price Override & Notes
                      TextFormField(
                        controller: _priceOverrideController,
                        decoration: const InputDecoration(
                          labelText: 'Alınan Ücret (₺)',
                          prefixIcon: Icon(Icons.payments),
                          helperText:
                              'Hizmet tutarlarından farklıysa değiştirebilirsiniz (Örn: indirim)',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _isPriceOverridden = true;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'İşlem Notu',
                          prefixIcon: Icon(Icons.note_alt),
                          hintText: 'Örn: saç bakımı hediye edildi',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _saveVisit(provider),
                  child: Text(
                    _status == 'Randevu'
                        ? (widget.existingVisit != null
                              ? 'RANDEVUYU GÜNCELLE'
                              : 'RANDEVUYU KAYDET')
                        : (widget.existingVisit != null
                              ? 'İŞLEMİ GÜNCELLE'
                              : 'İŞLEMİ KAYDET VE BİTİR'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
