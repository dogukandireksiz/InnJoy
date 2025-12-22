

class MenuItem{
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isActive;
  final int? preparationTime;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isActive = true,
    this.preparationTime,
  });

  //firebaseden veri Çekerken
  factory MenuItem.fromMap(Map<String, dynamic> data, String documentId) {
    return MenuItem(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(), // Hem int hem double gelirse hata vermez
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'general',
      isActive: data['isActive'] ?? true,
      preparationTime: data['preparationTime'],
    );
  }

    // Firebase'e veri gönderirken (Sipariş vb.) bu Çalışacak
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isActive': isActive,
      'preparationTime': preparationTime,
    };
  }



}







