import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/database_service.dart';
import 'admin_restaurant_reservations_screen.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  final String hotelName;
  final String restaurantId;

  const RestaurantSettingsScreen({
    super.key,
    required this.hotelName,
    required this.restaurantId,
  });

  @override
  State<RestaurantSettingsScreen> createState() =>
      _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descController;

  late TextEditingController _imageController;
  late TextEditingController _tableCountController;

  // State
  bool _isLoading = false;
  File? _imageFile;

  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _imageController = TextEditingController();
    _tableCountController = TextEditingController(
      text: '20',
    ); // Default 20 tables

    _loadSettings();
  }

  void _loadSettings() {
    _db.getRestaurantSettings(widget.hotelName, widget.restaurantId).listen((
      data,
    ) {
      if (data != null && mounted) {
        setState(() {
          if (_nameController.text.isEmpty) {
            _nameController.text = data['name'] ?? '';
          }
          if (_descController.text.isEmpty) {
            _descController.text = data['description'] ?? '';
          }
          if (_imageController.text.isEmpty) {
            _imageController.text = data['imageUrl'] ?? '';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _imageController.text = ''; // Clear URL if local file is picked
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Upload image if local file selected
      String imageUrl = _imageController.text;
      if (_imageFile != null) {
        // Need to implement a generic image upload or use menu item upload slightly modified
        // For now, reusing uploadMenuItemImage as it puts it in a restaurant folder
        imageUrl = await _db.uploadMenuItemImage(
          _imageFile!,
          widget.hotelName,
          widget.restaurantId,
        );
      }

      // 2. Save Data
      await _db
          .updateRestaurantSettings(widget.hotelName, widget.restaurantId, {
            'name': _nameController.text,
            'description': _descController.text,
            'imageUrl': imageUrl,
            'tableCount': int.tryParse(_tableCountController.text) ?? 20,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF137fec);

    return Scaffold(
      backgroundColor: const Color(0xFFf6f7f8),
      body: CustomScrollView(
        slivers: [
          // 1. Collapsible Hero Header
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHeaderImage(),
                  // Gradient overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                  // Edit Image Button centered
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white70),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Change Cover',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 2. Form Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101922),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'General Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card Wrapper for Inputs
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildPremiumTextField(
                            label: 'Restaurant Name',
                            controller: _nameController,
                            icon: Icons.store,
                          ),
                          const Divider(height: 32, thickness: 0.5),
                          _buildPremiumTextField(
                            label: 'Description',
                            controller: _descController,
                            icon: Icons.description,
                            maxLines: 4,
                          ),
                          const Divider(height: 32, thickness: 0.5),
                          _buildPremiumTextField(
                            label: 'Cover Image URL',
                            controller: _imageController,
                            icon: Icons.link,
                            onChanged: (val) {
                              setState(() {
                                _imageFile =
                                    null; // Switch to URL mode if typing
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (_) => AdminRestaurantReservationsScreen(
                                 hotelName: widget.hotelName,
                                 restaurantId: widget.restaurantId,
                               ),
                             ),
                           );
                        },
                        icon: const Icon(Icons.list_alt),
                        label: const Text('View Reservations'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveSettings,
        backgroundColor: primaryColor,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          _isLoading ? 'Saving...' : 'Save Changes',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    } else if (_imageController.text.isNotEmpty) {
      final imageUrl = _imageController.text;
      
      // Eğer yerel asset ise (assets/ ile başlıyorsa)
      if (imageUrl.startsWith('assets/')) {
        return Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.image_not_supported,
              size: 50,
              color: Colors.grey,
            ),
          ),
        );
      }
      
      // Network URL
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
      );
    }
    return Container(
      color: Colors.grey[300],
      child: const Icon(
        Icons.image_not_supported,
        size: 50,
        color: Colors.grey,
      ),
    );
  }


  Widget _buildPremiumTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,

    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        color: Color(0xFF101922),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: const Color(0xFF137fec)),
        border: InputBorder.none, // Clean look inside card
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        alignLabelWithHint: true,
      ),
      validator: (value) =>
          value?.isEmpty ?? true ? 'This field is required' : null,
    );
  }
}









