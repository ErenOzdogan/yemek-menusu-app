import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // FİREBASE PAKETİ EKLENDİ
import 'sayfalar/onboarding_sayfasi.dart';

// Firebase kurulumu zaman aldığı için (asenkron işlem) fonksiyonu 'Future' ve 'async' yaptık
Future<void> main() async {
  // Flutter motoru çalışmadan önce uygulamanın kök yapısının hazır olmasını sağlar
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i projede başlatır ve google-services.json dosyasını okur
  await Firebase.initializeApp();

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
        primaryColor: const Color(0xFF0D47A1), // Kurumsal Lacivert
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
      ),
      // Senin klasör yapına uygun başlangıç sayfası
      home: const OnboardingSayfasi(),
    );
  }
}