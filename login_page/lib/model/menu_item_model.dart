import 'package:login_page/model/user_model.dart';

class MenuItem{
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category

  });

  //firebaseden veri çekerken
  factory MenuItem.fromMap(Map<String, dynamic> data, String documentId) {
    return MenuItem(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(), // Hem int hem double gelirse hata vermez
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'general',
    );
  }

    // Firebase'e veri gönderirken (Sipariş vb.) bu çalışacak
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
    };
  }



}