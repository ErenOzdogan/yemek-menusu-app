import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'sayfalar/onboarding_sayfasi.dart';
import 'sayfalar/yemek_menusu_sayfasi.dart';
import 'package:belediye_menu_app/services/bildirim_servisi.dart';

final GlobalKey<NavigatorState> navigatorKey =
GlobalKey<NavigatorState>();

DateTime _bildirimTarihiniHesapla(String? payload) {
  DateTime tarih = DateTime.now();

  if (payload == 'yarin') {
    tarih = tarih.add(const Duration(days: 1));
  }

  return DateTime(
    tarih.year,
    tarih.month,
    tarih.day,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp();

  await BildirimServisi.init();

  final String? ilkBildirimPayload =
  await BildirimServisi.ilkAcilisPayloadiniAl();

  runApp(
    BelediyeMenuApp(
      ilkBildirimPayload: ilkBildirimPayload,
    ),
  );
}

class BelediyeMenuApp extends StatefulWidget {
  final String? ilkBildirimPayload;

  const BelediyeMenuApp({
    super.key,
    this.ilkBildirimPayload,
  });

  @override
  State<BelediyeMenuApp> createState() =>
      _BelediyeMenuAppState();
}

class _BelediyeMenuAppState extends State<BelediyeMenuApp> {
  @override
  void initState() {
    super.initState();

    BildirimServisi.bildirimeTiklaninca =
        _bildirimdenMenuyuAc;
  }

  void _bildirimdenMenuyuAc(String? payload) {
    if (payload != 'bugun' && payload != 'yarin') {
      return;
    }

    final DateTime acilacakTarih =
    _bildirimTarihiniHesapla(payload);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => YemekMenusuSayfasi(
            baslangicTarihi: acilacakTarih,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    BildirimServisi.bildirimeTiklaninca = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? ilkPayload =
        widget.ilkBildirimPayload;

    final DateTime? ilkAcilacakTarih =
    ilkPayload == 'bugun' || ilkPayload == 'yarin'
        ? _bildirimTarihiniHesapla(ilkPayload)
        : null;

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Akıllı Menü ve Geri Bildirim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
        ),
        useMaterial3: true,
      ),
      home: ilkAcilacakTarih != null
          ? YemekMenusuSayfasi(
        baslangicTarihi: ilkAcilacakTarih,
      )
          : const OnboardingSayfasi(),
    );
  }
}