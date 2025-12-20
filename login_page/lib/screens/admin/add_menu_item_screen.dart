import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../model/menu_item_model.dart';
import '../../service/database_service.dart';

class AddMenuItemScreen extends StatefulWidget {
  final String hotelName;
  final String restaurantId;
  final MenuItem? item;

  const AddMenuItemScreen({
    super.key,
    required this.hotelName,
    required this.restaurantId,
    this.item,
  });

  @override
  State<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  
  // State
  String? _selectedCategory;
  bool _isLoading = false;
  File? _imageFile;

  Map<String, String> _categoryMap = {};

  final Map<String, String> _roomServiceCategories = {
    'Breakfast': 'Breakfast',
    'Starters': 'Starters',
    'Main Courses': 'Main Courses',
    'Desserts': 'Desserts',
    'Drinks': 'Drinks',
    'Night Menu': 'Night Menu',
  };

  final Map<String, String> _restaurantCategories = {
    'Specials': 'Specials',
    'Starters': 'Starters',
    'Main Courses': 'Main Courses',
    'Desserts': 'Desserts',
    'Alcoholic Drinks': 'Alcoholic Drinks',
    'Non-Alcoholic Drinks': 'Non-Alcoholic Drinks',
    'Breakfast': 'Breakfast',
    'Snacks': 'Snacks',
    'Kids Menu': 'Kids Menu',
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize categories based on context
    if (widget.restaurantId == 'room_service') {
      _categoryMap = _roomServiceCategories;
    } else {
      _categoryMap = _restaurantCategories;
    }

    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descController = TextEditingController(text: widget.item?.description ?? '');
    _priceController = TextEditingController(text: widget.item?.price.toString() ?? '');
    _imageController = TextEditingController(text: widget.item?.imageUrl ?? '');
    
    _selectedCategory = widget.item?.category;
    
    // Ensure selected category is valid for this context (if editing)
    if (_selectedCategory != null && !_categoryMap.containsKey(_selectedCategory)) {
       // Dictionary mismatch? Keep it but it might not show in dropdown properly if strict.
       // For now, let's allow it to start as is, or maybe add it map temporarily?
       // Usually better to just leave it and let dropdown match if keys match.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final double price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;
      
      String imageUrl = _imageController.text.trim();

      // Upload if new file selected
      if (_imageFile != null) {
        imageUrl = await DatabaseService().uploadMenuItemImage(
          _imageFile!, 
          widget.hotelName, 
          widget.restaurantId
        );
      }

      final newItem = MenuItem(
        id: widget.item?.id ?? '',
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: price,
        imageUrl: imageUrl,
        category: _selectedCategory!,
        isActive: true, // Default active
      );

      if (widget.item != null) {
        await DatabaseService().updateMenuItem(
          widget.hotelName,
          widget.restaurantId,
          widget.item!.id,
          newItem,
        );
      } else {
        await DatabaseService().addMenuItem(
          widget.hotelName,
          widget.restaurantId,
          newItem,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Design matching the screenshot
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light grey background
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Add New Item' : 'Edit Item',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Photo Section ---
                    const Text('Product Photo', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), // Should be dashed ideally
                        ),
                        child: _imageFile != null 
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              )
                            : (_imageController.text.isNotEmpty 
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      _imageController.text,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_,__,___) => _buildPlaceholder(),
                                    ),
                                  )
                                : _buildPlaceholder()),
                      ),
                    ),
                    // Invisible URL input for now (or visible if we want to allow typing)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextFormField(
                        controller: _imageController,
                         decoration: InputDecoration(
                          hintText: 'Photo URL',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (val) => setState((){}),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Name ---
                    _buildSectionTitle('Item Name'),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'e.g. Grilled Meatballs',
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),

                    // --- Description ---
                    const SizedBox(height: 16),
                    _buildSectionTitle('Description'),
                    _buildTextField(
                      controller: _descController,
                      hint: 'Ingredients, serving style etc.',
                      maxLines: 4,
                    ),

                    // --- Category ---
                    const SizedBox(height: 16),
                    _buildSectionTitle('Category'),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(12), // Rounded popup
                      dropdownColor: Colors.white,
                      elevation: 4,
                      hint: const Text('Select Category'),
                      items: _categoryMap.keys.map((key) {
                        return DropdownMenuItem(
                          value: key,
                          child: Text(_categoryMap[key]!),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                        ),
                      ),
                      validator: (value) => value == null ? 'Please select a category' : null,
                    ),

                    // --- Price ---
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Price'),
                        _buildTextField(
                          controller: _priceController,
                          hint: '0.00',
                          suffixText: '₺',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40), // Spacer
                  ],
                ),
              ),
            ),
          ),
          
          // --- Bottom Button ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6), // Blue like screenshot
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.check, color: Colors.white),
                label: Text(
                  _isLoading ? 'Saving...' : 'Add Item', 
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF), // Light blue
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.camera_alt, color: Color(0xFF3B82F6), size: 30),
        ),
        const SizedBox(height: 12),
        const Text('Upload Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text('PNG, JPG (Max 5MB)', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)), // Slate-500 equivalent
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        suffixText: suffixText,
        suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
