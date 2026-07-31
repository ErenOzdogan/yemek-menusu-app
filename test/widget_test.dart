import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:belediye_menu_app/sayfalar/onboarding_sayfasi.dart';

void main() {
  testWidgets('Onboarding sayfasi yukleme testi', (WidgetTester tester) async {
    // Uygulamamızı test ortamında ayağa kaldırıyoruz
    await tester.pumpWidget(const MaterialApp(
      home: OnboardingSayfasi(),
    ));

    // Ekranın açıldığını ve "HOŞ GELDİNİZ!" yazısının göründüğünü doğruluyoruz
    expect(find.text('HOŞ GELDİNİZ!'), findsOneWidget);
  });
}