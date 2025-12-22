import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  final _imageUrlController = TextEditingController();
  final _capacityController = TextEditingController(text: '50');
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isPublished = true; // Default: Yayınla aÇık
  String? _selectedImage; // Asset path or URL
  File? _imageFile;
  
  // Validation error tracking
  bool _dateError = false;
  bool _timeError = false;
  
  String? _selectedCategory;
  final List<String> _categories = [
    'Entertainment',
    'Wellness & Life',
    'Sports',
    'Kids',
    'Food & Beverage'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final e = widget.eventToEdit!;
      _eventNameController.text = e['title'] ?? '';
      _descriptionController.text = e['description'] ?? '';
      _locationController.text = e['location'] ?? '';
      _capacityController.text = (e['capacity'] ?? 50).toString();
      _isPublished = e['isPublished'] ?? false;
      _selectedImage = e['imageAsset'];
      _selectedCategory = e['category'];
      
      // Timestamp to DateTime
      if (e['date'] != null) {
        if (e['date'] is Timestamp) {
          _selectedDate = (e['date'] as Timestamp).toDate();
        } else if (e['date'] is DateTime) {
          _selectedDate = e['date'];
        }
      }

      // Time conversion
      if (e['timeRaw'] != null) {
         final parts = (e['timeRaw'] as String).split(':');
         if (parts.length == 2) {
           _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
         }
      }

      if (_selectedImage != null && _selectedImage!.startsWith('http')) {
        _imageUrlController.text = _selectedImage!;
      }
    }
    _imageUrlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    if (_imageFile == null) {
      setState(() {
        _selectedImage = _imageUrlController.text;
      });
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    // _imageUrlController.dispose(); // Removing standard dispose to avoid issues if re-initializing, or keeping it but ensuring clean state.
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _selectedImage = null; // Prioritize local file
      });
    }
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

  void _selectTime(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('OK', style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                    )),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  _selectedTime?.hour ?? 12,
                  _selectedTime?.minute ?? 0,
                ),
                onDateTimeChanged: (val) {
                  setState(() {
                    _selectedTime = TimeOfDay.fromDateTime(val);
                    _timeError = false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveEvent() async {
    // Check date and time validation
    setState(() {
      _dateError = _selectedDate == null;
      _timeError = _selectedTime == null;
    });
    
    if (!_formKey.currentState!.validate() || _dateError || _timeError) {
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

      // Upload if new file selected
      if (_imageFile != null) {
        try {
          _selectedImage = await DatabaseService().uploadEventImage(
            _imageFile!, 
            widget.hotelName
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
          }
          return;
        }
      }

      final eventData = {
        'title': _eventNameController.text,
        'description': _descriptionController.text, // New field, make sure to display it if needed
        'location': _locationController.text,
        'capacity': int.parse(_capacityController.text),
        'category': _selectedCategory,
        'registered': widget.eventToEdit?['registered'] ?? 0,
        'isPublished': _isPublished,
        'imageAsset': _selectedImage ?? 'assets/images/arkaplanyok.png', // Fallback or URL
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
              SnackBar(content: Text('${_eventNameController.text} created'), backgroundColor: Colors.green),
            );
          }
        } else {
          // Update
          await DatabaseService().updateEvent(widget.hotelName, widget.eventToEdit!['id'], eventData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${_eventNameController.text} updated'), backgroundColor: Colors.green),
            );
          }
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Add Image',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    // 1. Çâ€œnce dosya varsa göster
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_imageFile!, fit: BoxFit.cover),
      );
    }
    
    // 2. URL girilmişse göster
    if (_imageUrlController.text.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _imageUrlController.text,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    }
    
    // 3. SeÇili görsel varsa (düzenleme modunda)
    if (_selectedImage != null && _selectedImage!.isNotEmpty) {
      if (_selectedImage!.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            _selectedImage!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          ),
        );
      } else if (_selectedImage!.startsWith('assets')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            _selectedImage!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          ),
        );
      }
    }
    
    // 4. HiÇbiri yoksa placeholder göster
    return _buildPlaceholder();
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
          widget.eventToEdit == null ? 'New Event' : 'Edit Event',
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
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _buildImagePreview(),
                ),
              ),

              // Image URL Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'or Image URL',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        hintText: 'https://example.com/image.jpg',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.link, color: Colors.grey[500]),
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
                      keyboardType: TextInputType.url,
                    ),
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
                      'Event Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Event Name
                    const Text(
                      'Event Name',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _eventNameController,
                      decoration: InputDecoration(
                        hintText: 'Ex: Karaoke Night',
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
                          return 'Event name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Kategori Dropdown
                    const Text(
                      'Category',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        hintText: 'Select Category',
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
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                      validator: (v) => v == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Detailed information about the event...',
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
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Date and Time Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _dateError ? Colors.red : Colors.grey[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedDate != null ? _formatDate(_selectedDate!) : 'Select Date',
                                          style: TextStyle(color: _selectedDate != null ? Colors.black87 : Colors.grey[400], fontSize: 14),
                                        ),
                                      ),
                                      Icon(Icons.calendar_today, color: _dateError ? Colors.red : Colors.grey[600], size: 20),
                                    ],
                                  ),
                                ),
                              ),
                              if (_dateError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6, left: 4),
                                  child: Text('Select a date', style: TextStyle(color: Colors.red[700], fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectTime(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _timeError ? Colors.red : Colors.grey[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedTime != null ? _formatTime(_selectedTime!) : 'Select Time',
                                          style: TextStyle(color: _selectedTime != null ? Colors.black87 : Colors.grey[400], fontSize: 14),
                                        ),
                                      ),
                                      Icon(Icons.access_time, color: _timeError ? Colors.red : Colors.grey[600], size: 20),
                                    ],
                                  ),
                                ),
                              ),
                              if (_timeError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6, left: 4),
                                  child: Text('Select a time', style: TextStyle(color: Colors.red[700], fontSize: 12)),
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
                              const Text('Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _locationController,
                                decoration: InputDecoration(
                                  hintText: 'Poolside',
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
                                    return 'Location is required';
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
                              const Text('Capacity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
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
                                    return 'Capacity is required';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Enter a number';
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
                    const Text('Visibility', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
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
                                const Text('Publish', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                                Text('Make event visible to guests.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isPublished,
                            onChanged: (value) => setState(() => _isPublished = value),
                            activeThumbColor: Colors.blue,
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
                    widget.eventToEdit == null ? 'Save' : 'Save Changes',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}










