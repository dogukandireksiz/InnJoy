import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // <-- EKLENDİ (Durum yönetimi)
import 'package:flutter_localizations/flutter_localizations.dart'; // <-- EKLENDİ (Dil desteği)
import 'package:login_page/l10n/app_localizations.dart'; // otomatik üretilen çeviriler (package import)

// Kendi dosya yolların:
import 'package:login_page/widgets/auth_wrapper.dart';
import 'firebase_options.dart';
// 'screens/screens.dart' and 'service/auth.dart' are not used here; imports removed to silence analyzer warnings.
import 'providers/language_provider.dart'; // <-- EKLENDİ (Senin oluşturduğun provider dosyasının yolu)

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    // Uygulamayı Provider ile sarmalıyoruz ki her yerden dile erişebilelim
    ChangeNotifierProvider(
      create: (context) => LanguageProvider(),
      child: const InnJoyHotelApp(),
    ),
  );
}

class InnJoyHotelApp extends StatelessWidget {
  const InnJoyHotelApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider'dan güncel dili dinliyoruz
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InnJoy Hotel', // Uygulama adı
      // --- DİL AYARLARI BAŞLANGICI ---
      locale:
          languageProvider.appLocale, // Provider'daki seçili dil (en veya tr)

      supportedLocales: const [
        Locale('en', ''), // İngilizce
        Locale('tr', ''), // Türkçe
      ],

      localizationsDelegates: const [
        AppLocalizations.delegate, // Bizim oluşturduğumuz çeviriler
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // --- DİL AYARLARI BİTİŞİ ---
      home: const AuthWrapper(),
      restorationScopeId: null,
    );
  }
}
