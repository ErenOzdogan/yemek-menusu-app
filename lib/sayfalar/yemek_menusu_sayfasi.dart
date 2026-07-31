import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_servis.dart';

class YemekMenusuSayfasi extends StatefulWidget {
  const YemekMenusuSayfasi({Key? key}) : super(key: key);

  @override
  State<YemekMenusuSayfasi> createState() => _YemekMenusuSayfasiState();
}

class _YemekMenusuSayfasiState extends State<YemekMenusuSayfasi> {
  final Color primaryBlue = const Color(0xFF003893);
  final Color lightBlueBg = const Color(0xFFE8EAF6);
  final Color textGray = const Color(0xFF757575);

  late DateTime _seciliTarih;
  SharedPreferences? _prefs;
  late Stream<QuerySnapshot> _menuStream;

  final List<String> _aylar = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
  final List<String> _gunler = ['', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  @override
  void initState() {
    super.initState();
    DateTime bugun = DateTime.now();

    if (bugun.weekday == 6) {
      bugun = bugun.add(const Duration(days: 2));
    } else if (bugun.weekday == 7) {
      bugun = bugun.add(const Duration(days: 1));
    }

    _seciliTarih = bugun;

    // === YENİ EKLENEN KISIM ===
    // Veritabanı bağlantısını sayfa açıldığında sadece 1 kez kuruyoruz!
    _menuStream = FirebaseFirestore.instance.collection('gunluk_menu').snapshots();

    _otomatikMenuKontrolVeGuncelle();
    _hafizayiYukle();
  }

  Future<void> _hafizayiYukle() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  Future<void> _otomatikMenuKontrolVeGuncelle() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('gunluk_menu').get();

      String arananGun = _seciliTarih.day.toString();
      String arananAyAdi = _aylar[_seciliTarih.month];
      String arananAyRakam = _seciliTarih.month.toString().padLeft(2, '0');

      bool menuVarMi = snapshot.docs.any((doc) {
        String dbTarih = doc['tarih'].toString();
        return dbTarih.contains(arananGun) &&
            (dbTarih.contains(arananAyAdi) || dbTarih.contains(arananAyRakam));
      });

      if (!menuVarMi) {
        MenuServis servis = MenuServis();
        await servis.haftalikMenuyuCekVeKaydet();
      }
    } catch (e) {
      print("Otomatik kontrol hatası: $e");
    }
  }

  void _oncekiGun() {
    if (_seciliTarih.weekday == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçmiş haftaların menüsü görüntülenemez.'), duration: Duration(seconds: 2)),
      );
      return;
    }
    setState(() {
      do {
        _seciliTarih = _seciliTarih.subtract(const Duration(days: 1));
      } while (_seciliTarih.weekday == 6 || _seciliTarih.weekday == 7);
    });
  }

  void _sonrakiGun() {
    if (_seciliTarih.weekday == 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gelecek haftanın menüsü henüz sisteme yüklenmedi.'), duration: Duration(seconds: 2)),
      );
      return;
    }
    setState(() {
      do {
        _seciliTarih = _seciliTarih.add(const Duration(days: 1));
      } while (_seciliTarih.weekday == 6 || _seciliTarih.weekday == 7);
    });
  }

  String _tarihFormatla(DateTime tarih) {
    String gun = tarih.day.toString();
    String ay = _aylar[tarih.month];
    String yil = tarih.year.toString();
    String haftaninGunu = _gunler[tarih.weekday];
    return "$gun $ay $yil\n$haftaninGunu";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: BottomWaveClipper(),
              child: Container(
                height: 160,
                color: primaryBlue,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildTopBar(context),
                const SizedBox(height: 20),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                      stream: _menuStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: primaryBlue));
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text("Veriler çekilirken hata oluştu."));
                      }

                      var docs = snapshot.data?.docs ?? [];
                      Map<String, dynamic>? gunlukVeri;
                      String? seciliBelgeId;

                      String arananGun = _seciliTarih.day.toString();
                      String arananAyAdi = _aylar[_seciliTarih.month];
                      String arananAyRakam = _seciliTarih.month.toString().padLeft(2, '0');

                      for (var doc in docs) {
                        String dbTarih = doc['tarih'].toString();
                        if (dbTarih.contains(arananGun) && (dbTarih.contains(arananAyAdi) || dbTarih.contains(arananAyRakam))) {
                          gunlukVeri = doc.data() as Map<String, dynamic>;
                          seciliBelgeId = doc.id;
                          break;
                        }
                      }

                      List<Map<String, dynamic>> aktifMenu = [];
                      int toplamKalori = 0;

                      if (gunlukVeri != null) {
                        void yemekEkle(String key, int ortalamaKalori) {
                          if (gunlukVeri![key] != null && gunlukVeri![key].toString().trim().isNotEmpty) {
                            aktifMenu.add({'ad': gunlukVeri![key], 'kalori': ortalamaKalori});
                            toplamKalori += ortalamaKalori;
                          }
                        }

                        yemekEkle('corba', 150);
                        yemekEkle('ana_yemek', 450);
                        yemekEkle('yardimci_yemek', 300);
                        yemekEkle('tatli', 200);
                      }

                      return Column(
                        children: [
                          RichText(
                            text: TextSpan(
                              text: 'Yemek Menüsü ',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue),
                              children: [
                                TextSpan(
                                  text: '(${toplamKalori}kcal)',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textGray),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                children: [
                                  _buildMenuCard(aktifMenu),
                                  const SizedBox(height: 24),
                                  _buildInteractionBar(gunlukVeri, seciliBelgeId),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('assets/logo.png', height: 50, fit: BoxFit.contain),
          Positioned(
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: primaryBlue, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Map<String, dynamic>> aktifMenu) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _oncekiGun,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back_ios, color: primaryBlue, size: 22),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _tarihFormatla(_seciliTarih),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _sonrakiGun,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.arrow_forward_ios, color: primaryBlue, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade300, thickness: 1.5),
          const SizedBox(height: 16),

          if (aktifMenu.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  "Bu tarih için menü bulunmamaktadır.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: textGray, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ...aktifMenu.map((yemek) {
              return _buildYemekSatiri(yemek['ad'], yemek['kalori'].toString());
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildYemekSatiri(String yemekAdi, String kalori) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: '$yemekAdi ',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3),
                children: [
                  TextSpan(
                    text: '($kalori kcal)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textGray),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionBar(Map<String, dynamic>? gunlukVeri, String? belgeId) {
    int begeniSayisi = gunlukVeri != null && gunlukVeri.containsKey('begeni') ? gunlukVeri['begeni'] : 0;
    int begenmemeSayisi = gunlukVeri != null && gunlukVeri.containsKey('begenmeme') ? gunlukVeri['begenmeme'] : 0;
    int yorumSayisi = gunlukVeri != null && gunlukVeri.containsKey('yorum_sayisi') ? gunlukVeri['yorum_sayisi'] : 0;

    String? kullaniciOyu = _prefs?.getString('oy_$belgeId');
    bool begenildi = kullaniciOyu == 'begeni';
    bool begenilmedi = kullaniciOyu == 'begenmeme';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: _interactionDecoration(),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: primaryBlue, size: 24),
              const SizedBox(width: 8),
              Text(yorumSayisi.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: _interactionDecoration(),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _oyVer(belgeId, 'begeni'),
                child: Row(
                  children: [
                    Icon(
                        begenildi ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: begenildi ? Colors.green : primaryBlue,
                        size: 24
                    ),
                    const SizedBox(width: 6),
                    Text(
                        begeniSayisi.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: begenildi ? Colors.green : Colors.black87)
                    ),
                  ],
                ),
              ),
              Container(
                height: 20,
                width: 1,
                color: Colors.grey.shade400,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              GestureDetector(
                onTap: () => _oyVer(belgeId, 'begenmeme'),
                child: Row(
                  children: [
                    Text(
                        begenmemeSayisi.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: begenilmedi ? Colors.red : Colors.black87)
                    ),
                    const SizedBox(width: 6),
                    Icon(
                        begenilmedi ? Icons.thumb_down : Icons.thumb_down_outlined,
                        color: begenilmedi ? Colors.red : primaryBlue,
                        size: 24
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // === DİNAMİK VE "ANINDA TEPKİ VEREN" OY VERME FONKSİYONU ===
  Future<void> _oyVer(String? belgeId, String alanAdi) async {
    if (belgeId == null || _prefs == null) return;

    // 1. ZAMAN KONTROLÜ
    String? hata = _etkilesimHataMesaji();
    if (hata != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hata), duration: const Duration(seconds: 2)),
      );
      return;
    }

    String? oncekiOy = _prefs!.getString('oy_$belgeId');
    var docRef = FirebaseFirestore.instance.collection('gunluk_menu').doc(belgeId);

    try {
      if (oncekiOy == null) {
        // DURUM 1: Önce rengi ANINDA değiştir, sonra Firebase'e yolla
        await _prefs!.setString('oy_$belgeId', alanAdi);
        setState(() {}); // Renk saniyesinde yeşil/kırmızı olur!
        await docRef.update({alanAdi: FieldValue.increment(1)});
      }
      else if (oncekiOy == alanAdi) {
        // DURUM 2: Fikirden vazgeçti, rengi ANINDA boş yap
        await _prefs!.remove('oy_$belgeId');
        setState(() {});
        await docRef.update({alanAdi: FieldValue.increment(-1)});
      }
      else {
        // DURUM 3: Fikrini değiştirdi (Beğen'den Beğenmeme'ye), ANINDA değiştir
        await _prefs!.setString('oy_$belgeId', alanAdi);
        setState(() {});
        await docRef.update({
          oncekiOy: FieldValue.increment(-1),
          alanAdi: FieldValue.increment(1)
        });
      }
    } catch (e) {
      print("Oy verme hatası: $e");
    }
  }

  String? _etkilesimHataMesaji() {
    DateTime suAn = DateTime.now();
    DateTime bugun = DateTime(suAn.year, suAn.month, suAn.day);
    DateTime secilenGun = DateTime(_seciliTarih.year, _seciliTarih.month, _seciliTarih.day);

    if (secilenGun.isAfter(bugun)) {
      return "Henüz yenmemiş bir yemeği değerlendiremezsiniz! 😊";
    }
    if (secilenGun.isBefore(bugun)) {
      return "Geçmiş günlerin menüsü için oylama kapanmıştır.";
    }
    if (secilenGun.isAtSameMomentAs(bugun)) {
      if (suAn.hour < 12) {
        return "Değerlendirme yapmak için yemeğin servis edilmesini (12:00) beklemelisiniz. 🍽️";
      }
      if (suAn.hour >= 17) {
        return "Bugünün menüsü için değerlendirme süresi (17:00) sona ermiştir.";
      }
    }
    return null;
  }

  BoxDecoration _interactionDecoration() {
    return BoxDecoration(
      color: lightBlueBg,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 3)),
      ],
    );
  }
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.quadraticBezierTo(size.width / 2, size.height * 0.7, 0, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}