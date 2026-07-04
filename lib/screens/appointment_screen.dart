import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:uuid/uuid.dart';
import '../models/appointment.dart';
import '../providers/salon_provider.dart';
import '../theme/app_theme.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  String? _selectedBarberId;
  String? _currentBarberId;
  AppointmentDataSource? _dataSource;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalonProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RANDEVULAR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final effectiveBarberId = _selectedBarberId ?? (provider.barbers.isNotEmpty ? provider.barbers.first.id : null);
              _showAppointmentDialog(context, null, null, effectiveBarberId);
            },
            tooltip: 'Yeni Randevu',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 16 hours (7:00-23:00)
          const headerHeight = 120.0;
          final availableHeight = constraints.maxHeight - headerHeight;
          const totalSlots = 16;
          final timeIntervalHeight = (availableHeight / totalSlots).clamp(
            40.0,
            120.0,
          );

          final effectiveBarberId = _selectedBarberId ?? (provider.barbers.isNotEmpty ? provider.barbers.first.id : null);
          final filteredAppointments = provider.appointments.where((a) => a.barberId == effectiveBarberId).toList();

          // Re-create data source when barber changes or on first load
          if (_dataSource == null || _currentBarberId != effectiveBarberId) {
            _currentBarberId = effectiveBarberId;
            _dataSource = AppointmentDataSource(filteredAppointments);
          } else {
            _dataSource!.appointments = filteredAppointments;
          }

          return Column(
            children: [
              if (provider.barbers.isNotEmpty)
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.barbers.length,
                    itemBuilder: (context, index) {
                      final barber = provider.barbers[index];
                      final isSelected = barber.id == effectiveBarberId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(barber.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedBarberId = barber.id;
                              });
                            }
                          },
                          selectedColor: AppTheme.goldPrimary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: AppTheme.bgField,
                        ),
                      );
                    },
                  ),
                ),
              Expanded(
                child: SfCalendar(
                  view: CalendarView.week,
                  firstDayOfWeek: 1, // Monday
                  timeSlotViewSettings: TimeSlotViewSettings(
                    startHour: 7,
                    endHour: 23,
                    timeFormat: 'HH:mm',
                    timeInterval: const Duration(minutes: 60),
                    timeIntervalHeight: timeIntervalHeight,
                  ),
                  dataSource: _dataSource,
            allowDragAndDrop: true,
            dragAndDropSettings: const DragAndDropSettings(
              showTimeIndicator: true,
              allowNavigation: false,
            ),
            onDragEnd: (AppointmentDragEndDetails details) {
              if (details.appointment != null && details.droppingTime != null) {
                final droppingTime = details.droppingTime!;
                final now = DateTime.now();
                // Prevent dropping in the past
                if (droppingTime.isBefore(
                  now.subtract(const Duration(minutes: 5)),
                )) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Geçmiş bir tarihe randevu taşınamaz!'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                final appt = details.appointment as AppointmentModel;
                final updated = appt.copyWith(dateTime: droppingTime);
                Provider.of<SalonProvider>(
                  context,
                  listen: false,
                ).updateAppointment(updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Randevu saati güncellendi!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            onTap: (CalendarTapDetails details) {
              if (details.targetElement == CalendarElement.appointment &&
                  details.appointments != null &&
                  details.appointments!.isNotEmpty) {
                final appt = details.appointments!.first as AppointmentModel;
                _showAppointmentDialog(context, appt, appt.dateTime, effectiveBarberId);
              } else if (details.targetElement ==
                  CalendarElement.calendarCell) {
                final DateTime date = details.date ?? DateTime.now();
                _showAppointmentDialog(context, null, date, effectiveBarberId);
              }
            },
            // Theme customization for dark theme
            backgroundColor: AppTheme.bgDark,
            headerStyle: const CalendarHeaderStyle(
              textStyle: TextStyle(
                color: AppTheme.goldPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: AppTheme.bgCard,
            ),
            viewHeaderStyle: const ViewHeaderStyle(
              dayTextStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              dateTextStyle: TextStyle(
                color: AppTheme.textLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            todayHighlightColor: AppTheme.goldPrimary,
            cellBorderColor: Colors.white24,
          ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAppointmentDialog(
    BuildContext context,
    AppointmentModel? existing,
    DateTime? initialDate,
    String? barberId,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return _AppointmentDialog(
          existingAppointment: existing,
          initialDate: initialDate,
          barberId: barberId,
        );
      },
    );
  }
}

class _AppointmentDialog extends StatefulWidget {
  final AppointmentModel? existingAppointment;
  final DateTime? initialDate;
  final String? barberId;

  const _AppointmentDialog({this.existingAppointment, this.initialDate, this.barberId});

  @override
  State<_AppointmentDialog> createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<_AppointmentDialog> {
  final _formKey = GlobalKey<FormState>();

  List<String> _selectedCategories = [];
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  late int _durationMinutes;
  late TextEditingController _priceController;
  late TextEditingController _additionalPeopleController;
  late String _selectedColorHex;

  final List<String> _colors = [
    '#4CAF50', // Green
    '#795548', // Brown
    '#2196F3', // Blue
    '#E91E63', // Pink
    '#FF9800', // Orange
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAppointment;

    _titleController = TextEditingController(text: existing?.title ?? '');
    _selectedCategories = existing?.category.split(', ').where((c) => c.isNotEmpty).toList() ?? [];
    _selectedDate = existing?.dateTime ?? widget.initialDate ?? DateTime.now();
    _durationMinutes = existing?.durationMinutes ?? 60;
    _priceController = TextEditingController(
      text: existing != null
          ? (existing.price > 0 ? existing.price.toStringAsFixed(0) : '')
          : '',
    );
    _additionalPeopleController = TextEditingController(
      text: existing?.additionalPeople ?? '',
    );
    _selectedColorHex = existing?.colorHex ?? _colors[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _additionalPeopleController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
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
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
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
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _save(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<SalonProvider>(context, listen: false);

      final appointment = AppointmentModel(
        id:
            widget.existingAppointment?.id ??
            const Uuid().v4(),
        title: _titleController.text.trim(),
        category: _selectedCategories.isEmpty ? 'Genel' : _selectedCategories.join(', '),
        dateTime: _selectedDate,
        durationMinutes: _durationMinutes,
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        additionalPeople: _additionalPeopleController.text.trim(),
        colorHex: _selectedColorHex,
        barberId: widget.barberId,
      );

      if (widget.existingAppointment != null) {
        provider.updateAppointment(appointment);
      } else {
        provider.addAppointment(appointment);
      }

      Navigator.pop(context);
    }
  }

  void _delete(BuildContext context) {
    if (widget.existingAppointment != null) {
      final provider = Provider.of<SalonProvider>(context, listen: false);
      provider.deleteAppointment(widget.existingAppointment!.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalonProvider>(context, listen: false);

    final dateFormat = DateFormat('dd.MM.yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existingAppointment != null
                          ? 'Randevuyu Düzenle'
                          : 'Yeni Randevu',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Kategori (Çoklu Seçim)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    border: Border.all(color: Colors.white10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: provider.services.map((service) {
                      final isSelected = _selectedCategories.contains(service.name);
                      return CheckboxListTile(
                        title: Text('${service.name} (${service.price} ₺)', style: const TextStyle(color: AppTheme.textLight, fontSize: 14)),
                        value: isSelected,
                        activeColor: AppTheme.goldPrimary,
                        checkColor: Colors.black,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedCategories.add(service.name);
                            } else {
                              _selectedCategories.remove(service.name);
                            }
                            // Calculate total price
                            double total = 0;
                            for (var cat in _selectedCategories) {
                              try {
                                final s = provider.services.firstWhere((e) => e.name == cat);
                                total += s.price;
                              } catch (_) {}
                            }
                            _priceController.text = total > 0 ? total.toStringAsFixed(0) : '';
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                if (_selectedCategories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 12),
                    child: Text('Lütfen en az bir kategori seçin', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 20),

                // Müşteri İsmi / Başlık
                const Text(
                  'Müşteri İsmi / Başlık',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _titleController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final customers = provider.customers;
                    if (textEditingValue.text.isEmpty) {
                      return customers.map((c) => c.name);
                    }
                    return customers
                        .where(
                          (c) => c.name.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        )
                        .map((c) => c.name);
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _titleController.text = selection;
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                    // Sync external controller with autocomplete's internal one
                    controller.text = _titleController.text;
                    controller.addListener(() {
                      _titleController.text = controller.text;
                    });
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Müşteri seçin veya isim yazın',
                        suffixIcon: Icon(
                          Icons.person_search,
                          size: 20,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Gerekli' : null,
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: AppTheme.bgCard,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                leading: const Icon(
                                  Icons.person,
                                  color: AppTheme.goldMedium,
                                  size: 18,
                                ),
                                title: Text(
                                  option,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                onTap: () => onSelected(option),
                                dense: true,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Tarih ve Saat
                Row(
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tarih',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      dateFormat.format(_selectedDate),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: AppTheme.goldMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Başlangıç',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      timeFormat.format(_selectedDate),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: AppTheme.goldMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Süre
                const Text(
                  'Süre (Dakika)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: AppTheme.goldMedium,
                      ),
                      onPressed: () {
                        if (_durationMinutes > 15) {
                          setState(() {
                            _durationMinutes -= 15;
                          });
                        }
                      },
                    ),
                    Text(
                      '$_durationMinutes dk',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: AppTheme.goldMedium,
                      ),
                      onPressed: () {
                        setState(() {
                          _durationMinutes += 15;
                        });
                      },
                    ),
                    const Spacer(),
                    Text(
                      'Default (1 sa)',
                      style: TextStyle(
                        color: AppTheme.goldMedium.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Fiyat
                const Text(
                  'Fiyat (TL)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Fiyat'),
                ),
                const SizedBox(height: 20),

                // Diğer Kişiler
                const Text(
                  'Diğer Kişiler (Opsiyonel)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _additionalPeopleController,
                  decoration: const InputDecoration(hintText: 'İsim ekle...'),
                ),
                const SizedBox(height: 20),

                // Etiket Rengi
                const Text(
                  'Etiket Rengi',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: _colors.map((hex) {
                    final isSelected = _selectedColorHex == hex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColorHex = hex;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _hexToColor(hex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.existingAppointment != null)
                      TextButton(
                        onPressed: () => _delete(context),
                        child: const Text(
                          'Sil',
                          style: TextStyle(color: AppTheme.accentRed),
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'İptal',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _save(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: AppTheme.bgDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Kaydet',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<AppointmentModel> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    final dt = _getAppointment(index).dateTime;
    // Snap visually to the top of the hour
    return DateTime(dt.year, dt.month, dt.day, dt.hour, 0);
  }

  @override
  DateTime getEndTime(int index) {
    final appt = _getAppointment(index);
    final dt = appt.dateTime;
    final snappedStart = DateTime(dt.year, dt.month, dt.day, dt.hour, 0);
    // Keep the visual size at least 60 mins so text doesn't get cut off
    final visualDuration = appt.durationMinutes < 60 ? 60 : appt.durationMinutes;
    return snappedStart.add(Duration(minutes: visualDuration));
  }

  @override
  String getSubject(int index) {
    final appt = _getAppointment(index);
    // Format actual time to prepend to title since visual position is snapped
    final hour = appt.dateTime.hour.toString().padLeft(2, '0');
    final minute = appt.dateTime.minute.toString().padLeft(2, '0');
    return '${appt.title}\n$hour:$minute';
  }

  @override
  Color getColor(int index) {
    final hex = _getAppointment(index).colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  bool isAllDay(int index) {
    return false;
  }

  AppointmentModel _getAppointment(int index) {
    return appointments![index] as AppointmentModel;
  }
}
