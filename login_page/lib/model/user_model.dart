// Kullanıcı verilerini temsil eden model sınıfı.
// Bu veriler Firestore'da tutulacaktır. (İleride harcama vb. eklemeler yapılabilir.)

class UserModel {
  final String? uid;           // Firebase kullanıcı ID'si
  final String? nameSurname;   // Kullanıcının adı ve soyadı
  final String? email;         // Kullanıcının e-posta adresi (auth.dart ile tutarlı)
  final String? password;      // Kullanıcının şifresi (Normalde şifre Firestore'da tutulmaz!)
  final String? hotelName;     // Yöneticinin sorumlu olduğu otel ismi
  final String? role;          // Kullanıcı rolü (customer, admin vb.)

  UserModel({
    required this.uid,
    required this.nameSurname,
    required this.email,
    required this.password,
    this.hotelName,            // Opsiyonel parametre
    this.role = 'customer',    // Varsayılan rol: customer
  });

  // JSON'dan UserModel nesnesi oluşturur (Firestore'dan veri çekerken kullanılır)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json["uid"],
      nameSurname: json["name_username"] ?? json["username"],       // Firestore'daki "name_username" (yoksa username) alanı
      email: json["email"] ?? json["mailAddress"],    // Önce 'email', yoksa eski 'mailAddress' alanını oku (geriye uyumluluk)
      password: json["password"],          // Firestore'daki "password" alanı
      hotelName: json["hotelName"],        // Firestore'daki "hotelName" alanı
      role: json["role"] ?? 'customer',    // Firestore'daki "role" alanı
    );
  }

  // UserModel nesnesini JSON formatına çevirir (Firestore'a veri eklerken kullanılır)
  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "name_username": nameSurname,  // Firestore'da bu isimle kaydedilecek
      "email": email,                // Artık 'email' olarak kaydediliyor (auth.dart ile tutarlı)
      "password": password,
      "hotelName": hotelName,        // Otel ismini kaydet
      "role": role,                  // Rolü kaydet
    };
  }
}
