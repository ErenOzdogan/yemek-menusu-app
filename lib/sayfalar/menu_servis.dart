import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:belediye_menu_app/services/gemini_service.dart';

class MenuServis {
  final String _url = 'https://kahramanmaras.bel.tr/personel/yemek-menusu';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService = GeminiService();

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

  String _metniStandartlastir(String metin) {
    return metin
        .trim()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int _intDegereCevir(dynamic deger) {
    if (deger is num) {
      return deger.round();
    }

    return int.tryParse(deger.toString()) ?? 0;
  }

  int _kaloriBul(Map<dynamic, dynamic> sonuc, String yemekAdi) {
    if (yemekAdi.trim().isEmpty) {
      return 0;
    }

    final standartYemekAdi = _metniStandartlastir(yemekAdi);

    // Önce yemek adının tamamını eşleştir.
    for (final kayit in sonuc.entries) {
      final sonucYemekAdi =
      _metniStandartlastir(kayit.key.toString());

      if (sonucYemekAdi == standartYemekAdi) {
        return _intDegereCevir(kayit.value);
      }
    }

    // "Pilav & Yoğurt" gibi birden fazla yemeği ayır ve topla.
    final parcalar = yemekAdi
        .split(RegExp(r'\s*(?:&|\+|/)\s*'))
        .where((parca) => parca.trim().isNotEmpty)
        .toList();

    int toplam = 0;
    bool herhangiBiriBulundu = false;

    for (final parca in parcalar) {
      final standartParca = _metniStandartlastir(parca);

      for (final kayit in sonuc.entries) {
        final sonucYemekAdi =
        _metniStandartlastir(kayit.key.toString());

        if (sonucYemekAdi == standartParca) {
          toplam += _intDegereCevir(kayit.value);
          herhangiBiriBulundu = true;
          break;
        }
      }
    }

    return herhangiBiriBulundu ? toplam : 0;
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
          final sonuc = await _geminiService.kaloriHesapla([
            menu['corba']!,
            menu['ana_yemek']!,
            menu['yardimci_yemek']!,
            menu['tatli']!,
          ]);

          /*print("BUGÜN GEMINI SONUCU: $sonuc");
          print("BUGÜN MENÜ VERİSİ: $menu");*/

          int corbaKalori =
          _kaloriBul(sonuc, menu['corba'] ?? '');

          int anaKalori =
          _kaloriBul(sonuc, menu['ana_yemek'] ?? '');

          int yardimciKalori =
          _kaloriBul(sonuc, menu['yardimci_yemek'] ?? '');

          int tatliKalori =
          _kaloriBul(sonuc, menu['tatli'] ?? '');

          int toplamKalori =
              corbaKalori +
                  anaKalori +
                  yardimciKalori +
                  tatliKalori;

          // Eğer sayfada en az bir geçerli yemek varsa veritabanına kaydet
          if (menu['ana_yemek']!.isNotEmpty || menu['corba']!.isNotEmpty) {
            String temizTarihId = bugunTarih.replaceAll(',', '').replaceAll(' ', '_');
            await _firestore.collection('gunluk_menu').doc(temizTarihId).set({
              'tarih': bugunTarih,
              'corba': menu['corba'],
              'ana_yemek': menu['ana_yemek'],
              'yardimci_yemek': menu['yardimci_yemek'],
              'tatli': menu['tatli'],

              'corba_kalori': corbaKalori,
              'ana_yemek_kalori': anaKalori,
              'yardimci_yemek_kalori': yardimciKalori,
              'tatli_kalori': tatliKalori,
              'toplam_kalori': toplamKalori,

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
            final sonuc = await _geminiService.kaloriHesapla([
              menu['corba']!,
              menu['ana_yemek']!,
              menu['yardimci_yemek']!,
              menu['tatli']!,
            ]);

            /*print("HAFTALIK GEMINI SONUCU: $sonuc");
            print("HAFTALIK MENÜ VERİSİ: $menu");*/

            int corbaKalori =
            _kaloriBul(sonuc, menu['corba'] ?? '');

            int anaKalori =
            _kaloriBul(sonuc, menu['ana_yemek'] ?? '');

            int yardimciKalori =
            _kaloriBul(sonuc, menu['yardimci_yemek'] ?? '');

            int tatliKalori =
            _kaloriBul(sonuc, menu['tatli'] ?? '');
            int toplamKalori =
                corbaKalori +
                    anaKalori +
                    yardimciKalori +
                    tatliKalori;

            if (menu['ana_yemek']!.isNotEmpty || menu['corba']!.isNotEmpty) {
              String temizTarihId = tarih.replaceAll(',', '').replaceAll(' ', '_');
              await _firestore.collection('gunluk_menu').doc(temizTarihId).set({
                'tarih': tarih,
                'corba': menu['corba'],
                'ana_yemek': menu['ana_yemek'],
                'yardimci_yemek': menu['yardimci_yemek'],
                'tatli': menu['tatli'],

                'corba_kalori': corbaKalori,
                'ana_yemek_kalori': anaKalori,
                'yardimci_yemek_kalori': yardimciKalori,
                'tatli_kalori': tatliKalori,
                'toplam_kalori': toplamKalori,

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