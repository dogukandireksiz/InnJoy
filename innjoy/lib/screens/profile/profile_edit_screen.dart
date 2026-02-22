import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../utils/responsive_utils.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  late TextEditingController _nameController;
  final TextEditingController _urlController = TextEditingController();

  String? _photoUrl;
  File? _pickedImage;
  bool _isLoading = false;
  int _selectedTab = 0; // 0: Default, 1: Gallery, 2: Link

  final List<String> _defaultAvatars = [
    'assets/avatars/default_avatar.png',
    'assets/avatars/avatar_male.png',
    'assets/avatars/avatar_female.png',
  ];

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _photoUrl = user?.photoURL;
    
    // Determine initial tab based on photoUrl
    if (_photoUrl != null) {
      if (_photoUrl!.startsWith('http')) {
        _selectedTab = 2; // Link or Uploaded
        _urlController.text = _photoUrl!;
      } 
      // Note: We can't easily distinguish between uploaded URL and external URL, 
      // but we can check if it matches a default avatar path if we stored it as path.
      // However, FirebaseAuth stores typically full URLs.
      // If we stored local asset path in Firestore, we could check that.
      // For now, default to gallery/link view if it's a URL.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        _photoUrl = null; // Clear URL if local image is picked
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final ref = _storage.ref().child('user_avatars').child('${user.uid}.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String? newPhotoUrl = _photoUrl;

      // Logic to determine final photo URL
      if (_selectedTab == 0) {
        // Default Avatar selected (we need to potentially upload it or store path?)
        // FirebaseAuth photoURL typically expects a http URL. 
        // If we use assets, we might need to store it in a specific way or upload the asset.
        // For simplicity, let's assume we can store the asset path IF our app handles it.
        // But `NetworkImage` won't work with asset paths.
        // So we should probably upload the selected asset or use a public URL for it.
        // OR: We store it in Firestore as 'avatarPath' and use logic in ProfileScreen.
        // Let's store the asset path in photoURL and handle it in ProfileScreen.
        
        // Wait, current `_photoUrl` state holds the asset path?
        // Just assigning logic:
        // If user tapped a default avatar, _photoUrl should be set to that asset path.
      } else if (_selectedTab == 1) {
        if (_pickedImage != null) {
          final url = await _uploadImage(_pickedImage!);
          if (url != null) {
            newPhotoUrl = url;
          }
        }
      } else if (_selectedTab == 2) {
        if (_urlController.text.isNotEmpty) {
          newPhotoUrl = _urlController.text.trim();
        }
      }

      // Update Auth Profile
      await user.updateDisplayName(_nameController.text.trim());
      if (newPhotoUrl != null) {
        await user.updatePhotoURL(newPhotoUrl);
      }

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': _nameController.text.trim(),
        'photoURL': newPhotoUrl,
        'email': user.email, // Ensure email is there
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Update local state is automatic via FirebaseAuth stream usually, but let's be safe
      await user.reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Preview Area
                    Center(
                      child: Container(
                        width: ResponsiveUtils.wp(context, 120 / 375),
                        height: ResponsiveUtils.hp(context, 120 / 844),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE3F2FD),
                          image: DecorationImage(
                            image: _getProfileImage() ??
                                AssetImage(
                                    'assets/avatars/default_avatar.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: null,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 32)),

                    // Avatar Selection Label
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Change Profile Picture',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(context, 16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          _buildTab('Default', 0),
                          _buildTab('Gallery', 1),
                          _buildTab('Link', 2),
                        ],
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 24)),

                    // Tab Content
                    if (_selectedTab == 0) _buildDefaultTab(),
                    if (_selectedTab == 1) _buildGalleryTab(),
                    if (_selectedTab == 2) _buildLinkTab(),

                    SizedBox(height: ResponsiveUtils.spacing(context, 32)),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1677FF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1677FF) : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultTab() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: ResponsiveUtils.spacing(context, 16),
        mainAxisSpacing: ResponsiveUtils.spacing(context, 16),
      ),
      itemCount: _defaultAvatars.length,
      itemBuilder: (context, index) {
        final path = _defaultAvatars[index];
        final isSelected = _photoUrl == path && _pickedImage == null;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _photoUrl = path;
              _pickedImage = null;
              _urlController.clear();
            });
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: const Color(0xFF1677FF), width: 3)
                  : null,
            ),
            child: CircleAvatar(
              backgroundImage: AssetImage(path),
              backgroundColor: Colors.grey[200],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGalleryTab() {
    return Column(
      children: [
        if (_pickedImage != null)
          Container(
            height: ResponsiveUtils.hp(context, 150 / 844),
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
              image: DecorationImage(
                image: FileImage(_pickedImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_library),
          label: const Text('Choose from Gallery'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.spacing(context, 12),
              horizontal: ResponsiveUtils.spacing(context, 24),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkTab() {
    return Column(
      children: [
        TextFormField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'Image URL',
            hintText: 'https://example.com/image.png',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
            ),
            prefixIcon: const Icon(Icons.link),
          ),
          onChanged: (value) {
            setState(() {
              if (value.isNotEmpty) {
                _photoUrl = value;
                _pickedImage = null;
              }
            });
          },
        ),
      ],
    );
  }

  ImageProvider? _getProfileImage() {
    if (_pickedImage != null) {
      return FileImage(_pickedImage!);
    }
    if (_photoUrl != null) {
      if (_photoUrl!.startsWith('assets/')) {
        return AssetImage(_photoUrl!);
      }
      return NetworkImage(_photoUrl!);
    }
    return null;
  }
}
