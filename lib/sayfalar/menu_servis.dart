import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuServis {
  final String _url = 'https://kahramanmaras.bel.tr/personel/yemek-menusu';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- YENİ: AKILLI YEMEK KATEGORİZASYON ALGORİTMASI ---
  Map<String, String> _kategorizeEt(List<String> kaplar) {
    // Sadece içi dolu olan kutuları al
    List<String> doluKaplar = kaplar.where((k) => k.isNotEmpty).toList();

    String c = '', a = '', y = '', t = '';
    List<String> kalanlar = [];

    // 1. ADIM: Çorbayı Bul (İçinde 'ÇORBA' geçen her şey banko çorbadır)
    for (String yemek in doluKaplar) {
      if (yemek.toUpperCase().contains('ÇORBA')) {
        c = yemek;
      } else {
        kalanlar.add(yemek); // Çorba olmayanları ayır
      }
    }

    // 2. ADIM: Tatlı veya İçecek Bul (Genelde menünün en sonuna yazılır)
    if (kalanlar.isNotEmpty) {
      t = kalanlar.last;
      kalanlar.removeLast(); // Bulduğumuz tatlıyı/içeceği listeden çıkar
    }

    // 3. ADIM: Ana Yemek (Çorbadan sonraki ilk yemek her zaman ana yemektir)
    if (kalanlar.isNotEmpty) {
      a = kalanlar.first;
      kalanlar.removeAt(0);
    }

    // 4. ADIM: Yardımcı Yemek (Geriye 2 tane bile kalsa -örn: salata ve ayran- birleştir)
    if (kalanlar.isNotEmpty) {
      y = kalanlar.join(' & '); // 'Çoban Salata & Ayran' şeklinde birleştirir
    }

    return {
      'corba': c,
      'ana_yemek': a,
      'yardimci_yemek': y,
      'tatli': t
    };
  }

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

          final k1 = bugunKutusu.querySelector('.field-name-field-catering-item1 .field-item, .field-name-field-catering-item-1 .field-item')?.text.trim() ?? '';
          final k2 = bugunKutusu.querySelector('.field-name-field-catering-item2 .field-item, .field-name-field-catering-item-2 .field-item')?.text.trim() ?? '';
          final k3 = bugunKutusu.querySelector('.field-name-field-catering-item3 .field-item, .field-name-field-catering-item-3 .field-item')?.text.trim() ?? '';
          final k4 = bugunKutusu.querySelector('.field-name-field-catering-item4 .field-item, .field-name-field-catering-item-4 .field-item')?.text.trim() ?? '';

          // YENİ SİSTEM: Kapları akıllı fonksiyona gönder, o doğru alanlara ayırsın
          Map<String, String> menu = _kategorizeEt([k1, k2, k3, k4]);

          // Eğer sayfada en az bir geçerli yemek varsa veritabanına kaydet
          if (menu['ana_yemek']!.isNotEmpty || menu['corba']!.isNotEmpty) {
            String temizTarihId = bugunTarih.replaceAll(',', '').replaceAll(' ', '_');
            await _firestore.collection('gunluk_menu').doc(temizTarihId).set({
              'tarih': bugunTarih,
              'corba': menu['corba'],
              'ana_yemek': menu['ana_yemek'],
              'yardimci_yemek': menu['yardimci_yemek'],
              'tatli': menu['tatli'],
              'kayit_zamani': FieldValue.serverTimestamp(), // Mevcut oyları silmemesi için 'merge: true' kullanılabilir ama sıfırdan çekiyoruz.
            }, SetOptions(merge: true)); // MERGE: TRUE Eklendi ki eski oylamalar kaybolmasın!

            print("✔️ Bugünün menüsü ($bugunTarih) akıllı sistemle çekildi!");
          }
        }

        // --- 2. AŞAMA: HAFTALIK TABLOYU ÇEKME (Alt Tablo) ---
        final satirlar = document.querySelectorAll('table.views-table tbody tr');

        for (var satir in satirlar) {
          final tarih = satir.querySelector('.views-field-field-menu-date')?.text.trim() ?? '';

          final k1 = satir.querySelector('.views-field-field-catering-item1, .views-field-field-catering-item-1')?.text.trim() ?? '';
          final k2 = satir.querySelector('.views-field-field-catering-item2, .views-field-field-catering-item-2')?.text.trim() ?? '';
          final k3 = satir.querySelector('.views-field-field-catering-item3, .views-field-field-catering-item-3')?.text.trim() ?? '';
          final k4 = satir.querySelector('.views-field-field-catering-item4, .views-field-field-catering-item-4')?.text.trim() ?? '';

          if (tarih.isNotEmpty) {
            Map<String, String> menu = _kategorizeEt([k1, k2, k3, k4]);

            if (menu['ana_yemek']!.isNotEmpty || menu['corba']!.isNotEmpty) {
              String temizTarihId = tarih.replaceAll(',', '').replaceAll(' ', '_');
              await _firestore.collection('gunluk_menu').doc(temizTarihId).set({
                'tarih': tarih,
                'corba': menu['corba'],
                'ana_yemek': menu['ana_yemek'],
                'yardimci_yemek': menu['yardimci_yemek'],
                'tatli': menu['tatli'],
                // Mevcut veriyi ezerken oyları sıfırlamasın diye merge: true kullanıyoruz
                'kayit_zamani': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              print("✔️ Tablodan $tarih menüsü akıllı sistemle çekildi!");
            }
          }
        }

        print("🚀 BÜTÜN İŞLEM TAMAM! Tüm veriler akıllı algoritma ile Firebase'e kaydedildi.");
      }
    } catch (e) {
      print("❌ Veri kazınırken bir hata oluştu: $e");
    }
  }
}