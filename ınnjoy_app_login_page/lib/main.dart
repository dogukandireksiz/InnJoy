import 'package:flutter/material.dart';

import 'login_screen.dart';

void main(List<String> args) {
  runApp(InnJoyHotelApp());
}

class InnJoyHotelApp extends StatelessWidget {
  const InnJoyHotelApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen());
  }
}
