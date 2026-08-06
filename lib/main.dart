import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'sayfalar/onboarding_sayfasi.dart';
import 'package:belediye_menu_app/services/bildirim_servisi.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp();

  // Bildirim servisini başlat
  await BildirimServisi.init();

  runApp(const BelediyeMenuApp());
}

class BelediyeMenuApp extends StatelessWidget {
  const BelediyeMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akıllı Menü ve Geri Bildirim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
        ),
        useMaterial3: true,
      ),
      home: const OnboardingSayfasi(),
    );
  }
}