import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';


class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("YÖNETİCİ PANELİ",style: TextStyle(color: Colors.black26),),
        actions: [
          IconButton(onPressed:() async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> const LoginScreen()));
          } , icon: const Icon(Icons.logout,color: Colors.amber,))
        ],

      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.security,size: 100,color: Colors.cyan,),
            SizedBox(height: 20,),
            Text("BURASI ADMİN SAYFASI"),
            
          ],
        ),
      ),
    );
  }
}