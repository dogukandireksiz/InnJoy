import 'package:flutter/material.dart';
import 'package:login_page/services/database_service.dart';
import '../../../utils/responsive_utils.dart';

class SpaFormScreen extends StatefulWidget {
  final String hotelName;
  final String? serviceId;
  final Map<String, dynamic>? initialData;

  const SpaFormScreen({
    super.key,
    required this.hotelName,
    this.serviceId,
    this.initialData,
  });

  @override
  State<SpaFormScreen> createState() => _SpaFormScreenState();
}

class _SpaFormScreenState extends State<SpaFormScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _durationController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialData?['name'] ?? '',
    );
    _descController = TextEditingController(
      text: widget.initialData?['description'] ?? '',
    );
    _durationController = TextEditingController(
      text: (widget.initialData?['duration'] ?? 60).toString(),
    );
    _priceController = TextEditingController(
      text: (widget.initialData?['price'] ?? 0).toString(),
    );
    _imageUrlController = TextEditingController(
      text: widget.initialData?['imageUrl'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text,
      'description': _descController.text,
      'duration': int.tryParse(_durationController.text) ?? 60,
      'price': double.tryParse(_priceController.text) ?? 0,
      'imageUrl': _imageUrlController.text,
      'updatedAt': DateTime.now(),
    };

    try {
      if (widget.serviceId != null) {
        await DatabaseService().updateSpaService(
          widget.hotelName,
          widget.serviceId!,
          data,
        );
      } else {
        await DatabaseService().addSpaService(widget.hotelName, data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteService() async {
    if (widget.serviceId == null) return;

    // Basit bir onay dialogu
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Are you sure you want to delete?"),
            content: const Text("This action cannot be undone."),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    await DatabaseService().deleteSpaService(
      widget.hotelName,
      widget.serviceId!,
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        title: const Text(
          'Edit Service',
          style: TextStyle(
            color: Color(0xFF0d141b),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFFF6F7F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0d141b),
            size: ResponsiveUtils.iconSize(context) * (20 / 24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        child: Column(
          children: [
            // Image Preview (Click to change URL for now, could be picker)
            GestureDetector(
              onTap: () {
                // For simplicity, showing a dialog to edit URL
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Image URL"),
                    content: TextField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        hintText: "Enter image URL",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {});
                        },
                        child: const Text(
                          "OK",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
                    ),
                  ),
                );
              },
              child: Container(
                height: ResponsiveUtils.hp(context, 240 / 844),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 24)),
                  color: Colors.grey[100],
                  boxShadow: _imageUrlController.text.isNotEmpty
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                  border: _imageUrlController.text.isEmpty
                      ? Border.all(
                          color: Colors.grey.shade300,
                          width: ResponsiveUtils.wp(context, 2 / 375),
                          style: BorderStyle.solid,
                        )
                      : null,
                  image: _imageUrlController.text.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(_imageUrlController.text),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {},
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: _imageUrlController.text.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: ResponsiveUtils.iconSize(context) * (48 / 24),
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                          Text(
                            'Add Image',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: ResponsiveUtils.sp(context, 16),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                          Text(
                            'or enter URL below',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: ResponsiveUtils.sp(context, 12),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 30)),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: ResponsiveUtils.iconSize(context) * (18 / 24),
                            ),
                            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                            Text(
                              "Change Image",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveUtils.sp(context, 14),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

            // Image URL Input Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image URL',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.sp(context, 14),
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0d141b),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                TextField(
                  controller: _imageUrlController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.link,
                      color: Color(0xFF64748B),
                    ),
                    hintText: 'https://example.com/image.jpg',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.spacing(context, 16),
                      vertical: ResponsiveUtils.spacing(context, 16),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
                      borderSide: BorderSide(
                        color: Color(0xFF137fec),
                        width: ResponsiveUtils.wp(context, 1.5 / 375),
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),

            // Form Fields
            _buildTextField("Service Name", _nameController, icon: Icons.spa),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            _buildTextField(
              "Description",
              _descController,
              maxLines: 4,
              icon: Icons.description,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    "Duration (min)",
                    _durationController,
                    isNumber: true,
                    icon: Icons.schedule,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 16)),
                Expanded(
                  child: _buildTextField(
                    "Price (₺)",
                    _priceController,
                    isNumber: true,
                    customPrefix: Text(
                      '₺',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(context, 20),
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 32)),

            // Actions
            // Actions
            SizedBox(
              width: double.infinity,
              height: ResponsiveUtils.hp(context, 56 / 844),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137fec),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
                  ),
                  shadowColor: Colors.blue.withValues(alpha: 0.3),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Save",
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(context, 18),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            if (widget.serviceId != null) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              TextButton.icon(
                onPressed: _isLoading ? null : _deleteService,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: Text(
                  "Delete Service",
                  style: TextStyle(color: Colors.redAccent, fontSize: ResponsiveUtils.sp(context, 16)),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.spacing(context, 12),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool isNumber = false,
    IconData? icon,
    Widget? customPrefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(context, 14),
            fontWeight: FontWeight.w500,
            color: Color(0xFF0d141b),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: customPrefix != null
                ? Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: customPrefix,
                  )
                : (icon != null
                      ? Icon(icon, color: const Color(0xFF64748B))
                      : null),
            prefixIconConstraints: customPrefix != null
                ? const BoxConstraints(minWidth: 0, minHeight: 0)
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.spacing(context, 16),
              vertical: ResponsiveUtils.spacing(context, 16),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
              borderSide: BorderSide(
                color: Color(0xFF137fec),
                width: ResponsiveUtils.wp(context, 1.5 / 375),
              ),
            ),
            hintText: "Enter $label".toLowerCase(),
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ],
    );
  }
}
