import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // FİREBASE PAKETİ EKLENDİ
import 'sayfalar/onboarding_sayfasi.dart';

// 1. KABLO (IMPORT): Bildirim servisini ana sayfaya çağırdık (Klasör adının 'services' olduğunu varsayıyorum)
import 'package:belediye_menu_app/services/bildirim_servisi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 2. KABLO (KONTAK): Firebase başlatıldıktan hemen sonra bildirim motorunu uyandırıyoruz!
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
        primaryColor: const Color(0xFF0D47A1), // Kurumsal Lacivert
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
      ),
      home: const OnboardingSayfasi(),
    );
  }
}