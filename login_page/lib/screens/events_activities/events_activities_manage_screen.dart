import 'package:flutter/material.dart';
import '../../service/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventsActivitiesManageScreen extends StatefulWidget {
  final String hotelName;
  final Map<String, dynamic>? eventToEdit;

  const EventsActivitiesManageScreen({
    super.key,
    required this.hotelName,
    this.eventToEdit,
  });

  @override
  State<EventsActivitiesManageScreen> createState() => _EventsActivitiesManageScreenState();
}

class _EventsActivitiesManageScreenState extends State<EventsActivitiesManageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController(text: '50');
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isPublished = false;
  String? _selectedImage; // Asset path for now
  
  // Mock image list for selection
  final List<String> _availableImages = [
    'assets/images/arkaplanyok.png',
    'assets/images/arkaplanyok1.png',
    'assets/images/arkaplan.jpg',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final e = widget.eventToEdit!;
      _eventNameController.text = e['title'] ?? '';
      _descriptionController.text = e['description'] ?? ''; // Assuming description field
      _locationController.text = e['location'] ?? '';
      _capacityController.text = (e['capacity'] ?? 50).toString();
      _isPublished = e['isPublished'] ?? false;
      _selectedImage = e['imageAsset'];
      
      // Timestamp to DateTime
      if (e['date'] != null) {
        if (e['date'] is Timestamp) {
          _selectedDate = (e['date'] as Timestamp).toDate();
        } else if (e['date'] is DateTime) {
          _selectedDate = e['date']; // For compatibility if passed as DateTime locally
        }
      }

      // Time conversion (stored as string "HH:MM AG/PM" or similar, stick to string for simplicity as per existing logic, or parse it)
      // The previous code stored time as string. Let's try to parse it or just set it if we stored it as discrete fields.
      // For simplicity, let's assume we store 'time' as a string in the previous dummy data.
      // But for better management, we should probably store hour/minute or a DateTime.
      // Existing dummy data used formatted string "4:00 PM - 5:00 PM".
      // Let's stick to generating that string, but for editing, we might lose precision if we don't parse.
      // For this task, I'll clear the time if it's complex, or try to parse if standard.
      // Let's just reset time for now if it's a new edit unless we store struct.
      // Actually, let's look at the read code. It was a string.
      // Let's add a todo or just keep it simple: User re-selects time or we parse simple "HH:MM".
      if (e['timeRaw'] != null) {
         // Assuming we will store 'timeRaw' as "HH:MM" for easier parsing back
         final parts = (e['timeRaw'] as String).split(':');
         if (parts.length == 2) {
           _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
         }
      }
    } else {
       _selectedImage = _availableImages.first;
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen tarih seçiniz'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen saat seçiniz'), backgroundColor: Colors.red),
        );
        return;
      }

      final timeString = _formatTime(_selectedTime!);
      // Combine date and time to sorting date
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final eventData = {
        'title': _eventNameController.text,
        'description': _descriptionController.text, // New field, make sure to display it if needed
        'location': _locationController.text,
        'capacity': int.parse(_capacityController.text),
        'registered': widget.eventToEdit?['registered'] ?? 0,
        'isPublished': _isPublished,
        'imageAsset': _selectedImage,
        'date': Timestamp.fromDate(dateTime),
        'time': timeString, // Display string
        'timeRaw': timeString, // For parsing back
        'updatedAt': FieldValue.serverTimestamp(),
      };

      try {
        if (widget.eventToEdit == null) {
          // Create
          eventData['createdAt'] = FieldValue.serverTimestamp();
          await DatabaseService().addEvent(widget.hotelName, eventData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${_eventNameController.text} oluşturuldu'), backgroundColor: Colors.green),
            );
          }
        } else {
          // Update
          await DatabaseService().updateEvent(widget.hotelName, widget.eventToEdit!['id'], eventData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${_eventNameController.text} güncellendi'), backgroundColor: Colors.green),
            );
          }
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.eventToEdit == null ? 'Yeni Etkinlik' : 'Etkinliği Düzenle',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upload Event Image Section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    if (_selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          _selectedImage!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(
                               height: 60,
                               child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                            );
                          },
                        ),
                      )
                    else 
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'Etkinlik Görseli',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final img = _availableImages[index];
                          final isSelected = img == _selectedImage;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = img;
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(img, fit: BoxFit.cover),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),

              // Event Details Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Etkinlik Detayları',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Event Name
                    const Text(
                      'Etkinlik Adı',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _eventNameController,
                      decoration: InputDecoration(
                        hintText: 'Örn: Sabah Yogası',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Etkinlik adı gereklidir';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'Açıklama',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Etkinlik hakkında detaylı bilgi...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Açıklama gereklidir';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Logistics Section
                    const Text(
                      'Lojistik',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),

                    // Date and Time Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tarih', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedDate != null ? _formatDate(_selectedDate!) : 'Tarih Seç',
                                          style: TextStyle(color: _selectedDate != null ? Colors.black87 : Colors.grey[400], fontSize: 14),
                                        ),
                                      ),
                                      Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Saat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectTime(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedTime != null ? _formatTime(_selectedTime!) : 'Saat Seç',
                                          style: TextStyle(color: _selectedTime != null ? Colors.black87 : Colors.grey[400], fontSize: 14),
                                        ),
                                      ),
                                      Icon(Icons.access_time, color: Colors.grey[600], size: 20),
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

                    // Location and Capacity Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Konum', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _locationController,
                                decoration: InputDecoration(
                                  hintText: 'Havuz kenarı',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[200]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[200]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Konum gerekli';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Kapasite', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _capacityController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '50',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[200]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[200]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Kapasite gerekli';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Sayı girin';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Visibility Section
                    const Text('Görünürlük', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 12),

                    // Publish Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Yayınla', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                                Text('Etkinliği misafirler için görünür yap.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isPublished,
                            onChanged: (value) => setState(() => _isPublished = value),
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.eventToEdit == null ? 'Kaydet' : 'Değişiklikleri Kaydet',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal', style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

