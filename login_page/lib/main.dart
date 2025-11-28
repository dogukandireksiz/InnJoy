// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'firebase_options.dart';

// import 'login_screen.dart';
// import 'home_screen.dart';
// import 'service/auth.dart';

// void main(List<String> args) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   runApp(InnJoyHotelApp());
// }

// class InnJoyHotelApp extends StatelessWidget {
//   const InnJoyHotelApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: StreamBuilder<User?>(
//         stream: Auth().authStateChanges,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             );
//           }

//           if (snapshot.hasData) {
//             // Kullanıcı giriş yaptı
//             return HomeScreen(userName: snapshot.data?.email ?? 'User');
//           } else {
//             // Kullanıcı giriş yapmadı
//             return const LoginScreen();
//           }
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_page/widgets/auth_wrapper.dart';
import 'firebase_options.dart';

import 'login_screen.dart';
import 'home_screen.dart';
import 'service/auth.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(InnJoyHotelApp());
}

class InnJoyHotelApp extends StatelessWidget {
  const InnJoyHotelApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
       home: const AuthWrapper(),restorationScopeId: null,
    );
  }
}
