// Kullanıcı verilerini temsil eden model sınıfı.
// Bu veriler Firestore'da tutulacaktır. (İleride harcama vb. eklemeler yapılabilir.)

class UserModel {
  final String? uid;           // Firebase kullanıcı ID'si
  final String? nameSurname;   // Kullanıcının adı ve soyadı
  final String? mailAddress;   // Kullanıcının e-posta adresi
  final String? password;      // Kullanıcının şifresi (Normalde şifre Firestore'da tutulmaz!)

  UserModel({
    required this.uid,
    required this.nameSurname,
    required this.mailAddress,
    required this.password,
  });

  // JSON'dan UserModel nesnesi oluşturur (Firestore'dan veri çekerken kullanılır)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json["uid"],
      nameSurname: json["username"],       // Firestore'daki "username" alanı
      mailAddress: json["mailAddress"],    // Firestore'daki "mailAddress" alanı
      password: json["password"],          // Firestore'daki "password" alanı
    );
  }

  // UserModel nesnesini JSON formatına çevirir (Firestore'a veri eklerken kullanılır)
  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "name_username": nameSurname,  // Firestore'da bu isimle kaydedilecek
      "mailAddress": mailAddress,
      "password": password,
    };
  }
}
