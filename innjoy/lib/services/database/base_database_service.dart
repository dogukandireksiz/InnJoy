import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

/// BaseDatabaseService - Abstract base class with shared Firebase instances.
/// All domain-specific services extend this class.
abstract class BaseDatabaseService {
  // Shared Firebase instances
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // --- SHARED IMAGE UPLOAD ---

  /// Upload menu item image to Firebase Storage
  Future<String> uploadMenuItemImage(
    File file,
    String hotelName,
    String restaurantId,
  ) async {
    // Check if it's room service or restaurant for path
    String pathSegment = 'restaurants/$restaurantId';
    if (restaurantId == 'room_service') {
      pathSegment = 'room_service';
    }

    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final ref = storage.ref().child(
      'hotels/$hotelName/$pathSegment/menu_images/$fileName',
    );

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload event image to Firebase Storage
  Future<String> uploadEventImage(File file, String hotelName) async {
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final ref = storage.ref().child(
      'hotels/$hotelName/events/event_images/$fileName',
    );

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
