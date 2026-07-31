import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuServis {
  final String _url = 'https://kahramanmaras.bel.tr/personel/yemek-menusu';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> haftalikMenuyuCekVeKaydet() async {
    try {
      print("Belediyenin sitesine bağlanılıyor...");
      final response = await http.get(Uri.parse(_url));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        // --- 1. AŞAMA: BUGÜNÜN MENÜSÜNÜ ÇEKME (Üst Kısım) ---
        final bugunKutusu = document.querySelector('.node-catering-menu');
        if (bugunKutusu != null) {
          final baslikSpan = document.querySelector('span[property="dc:title"]');
          String bugunTarih = "Bugün";

          if (baslikSpan != null) {
            String content = baslikSpan.attributes['content'] ?? '';
            final match = RegExp(r'\((.*?)\)').firstMatch(content);
            if (match != null) {
              bugunTarih = match.group(1) ?? bugunTarih;
            }
          }

          final kap1 = bugunKutusu.querySelector('.field-name-field-catering-item1 .field-item, .field-name-field-catering-item-1 .field-item')?.text.trim() ?? '';
          final kap2 = bugunKutusu.querySelector('.field-name-field-catering-item2 .field-item, .field-name-field-catering-item-2 .field-item')?.text.trim() ?? '';
          final kap3 = bugunKutusu.querySelector('.field-name-field-catering-item3 .field-item, .field-name-field-catering-item-3 .field-item')?.text.trim() ?? '';
          final kap4 = bugunKutusu.querySelector('.field-name-field-catering-item4 .field-item, .field-name-field-catering-item-4 .field-item')?.text.trim() ?? '';

          if (kap1.isNotEmpty) {
            String temizTarihId = bugunTarih.replaceAll(',', '').replaceAll(' ', '_');
            await _firestore.collection('gunluk_menu').doc(temizTarihId).set({
              'tarih': bugunTarih,
              'corba': kap1,
              'ana_yemek': kap2,
              'yardimci_yemek': kap3,
              'tatli': kap4,
              'kayit_zamani': FieldValue.serverTimestamp(),
            });
            print("✔️ Bugünün menüsü ($bugunTarih) başarıyla çekildi!");
          }
        }

        // --- 2. AŞAMA: HAFTALIK TABLOYU ÇEKME (Alt Tablo - Düzeltildi!) ---
        final satirlar = document.querySelectorAll('table.views-table tbody tr');

        for (var satir in satirlar) {
          final tarih = satir.querySelector('.views-field-field-menu-date')?.text.trim() ?? '';

          // HEM TİRELİ HEM TİRESİZ İHTİMALİ ARATLIYORUZ (item1 ve item-1)
          final kap1 = satir.querySelector('.views-field-field-catering-item1, .views-field-field-catering-item-1')?.text.trim() ?? '';
          final kap2 = satir.querySelector('.views-field-field-catering-item2, .views-field-field-catering-item-2')?.text.trim() ?? '';
          final kap3 = satir.querySelector('.views-field-field-catering-item3, .views-field-field-catering-item-3')?.text.trim() ?? '';
          final kap4 = satir.querySelector('.views-field-field-catering-item4, .views-field-field-catering-item-4')?.text.trim() ?? '';

          if (tarih.isNotEmpty && kap1.isNotEmpty) {
            String temizTarihId = tarih.replaceAll(',', '').replaceAll(' ', '_');
            await _firestore.collection('gunluk_menu').doc(temizTarihId).set({
              'tarih': tarih,
              'corba': kap1,
              'ana_yemek': kap2,
              'yardimci_yemek': kap3,
              'tatli': kap4,
              'kayit_zamani': FieldValue.serverTimestamp(),
            });
            print("✔️ Tablodan $tarih menüsü başarıyla çekildi!");
          }
        }

        print("🚀 BÜTÜN İŞLEM TAMAM! Tüm haftanın verisi Firebase'e gönderildi.");
      }
    } catch (e) {
      print("❌ Veri kazınırken bir hata oluştu: $e");
    }
  }
}