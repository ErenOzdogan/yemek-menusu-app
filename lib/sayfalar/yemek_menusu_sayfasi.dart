import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_servis.dart';
//import 'package:belediye_menu_app/services/gemini_service.dart';

class YemekMenusuSayfasi extends StatefulWidget {
  final DateTime? baslangicTarihi;

  const YemekMenusuSayfasi({
    super.key,
    this.baslangicTarihi,
  });

  @override
  State<YemekMenusuSayfasi> createState() =>
      _YemekMenusuSayfasiState();
}

class _YemekMenusuSayfasiState extends State<YemekMenusuSayfasi> {
  /*final GeminiService _geminiService = GeminiService();

  Map<String, int> _kaloriler = {};

  bool _kaloriYukleniyor = false;

  Future<void> _kalorileriHesapla(
      String belgeId,
      Map<String, dynamic> menu,
      ) async {
    if (_kaloriYukleniyor) return;

    _kaloriYukleniyor = true;

    try {
      final yemekler = <String>[];

      if ((menu['corba'] ?? '').toString().isNotEmpty) {
        yemekler.add(menu['corba']);
      }

      if ((menu['ana_yemek'] ?? '').toString().isNotEmpty) {
        yemekler.add(menu['ana_yemek']);
      }

      if ((menu['yardimci_yemek'] ?? '').toString().isNotEmpty) {
        yemekler.add(menu['yardimci_yemek']);
      }

      if ((menu['tatli'] ?? '').toString().isNotEmpty) {
        yemekler.add(menu['tatli']);
      }

      final sonuc = await _geminiService.kaloriHesapla(yemekler);

      int corbaKalori = 0;
      int anaKalori = 0;
      int yardimciKalori = 0;
      int tatliKalori = 0;

      if ((menu['corba'] ?? '').toString().isNotEmpty) {
        corbaKalori = (sonuc[menu['corba']] ?? 0) as int;
      }

      if ((menu['ana_yemek'] ?? '').toString().isNotEmpty) {
        anaKalori = (sonuc[menu['ana_yemek']] ?? 0) as int;
      }

      if ((menu['yardimci_yemek'] ?? '').toString().isNotEmpty) {
        yardimciKalori = (sonuc[menu['yardimci_yemek']] ?? 0) as int;
      }

      if ((menu['tatli'] ?? '').toString().isNotEmpty) {
        tatliKalori = (sonuc[menu['tatli']] ?? 0) as int;
      }

      int toplamKalori =
          corbaKalori +
              anaKalori +
              yardimciKalori +
              tatliKalori;

      await FirebaseFirestore.instance
          .collection('gunluk_menu')
          .doc(belgeId)
          .update({
        'corba_kalori': corbaKalori,
        'ana_yemek_kalori': anaKalori,
        'yardimci_yemek_kalori': yardimciKalori,
        'tatli_kalori': tatliKalori,
        'toplam_kalori': toplamKalori,
      });

      if (mounted) {
        setState(() {
          _kaloriler = sonuc.map(
                (key, value) => MapEntry(key.toString(), (value as num).toInt()),
          );
        });
      }
    } catch (e) {
      print(e);
    }

    _kaloriYukleniyor = false;
  }*/

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
    DateTime bugun =
        widget.baslangicTarihi ?? DateTime.now();

    if (bugun.weekday == 6) {
      bugun = bugun.add(const Duration(days: 2));
    } else if (bugun.weekday == 7) {
      bugun = bugun.add(const Duration(days: 1));
    }

    _seciliTarih = bugun;
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

      String arananGun = _seciliTarih.day.toString().padLeft(2, '0');
      String arananAyAdi = _aylar[_seciliTarih.month];
      String arananAyRakam = _seciliTarih.month.toString().padLeft(2, '0');

      String aramaMetni1 = "$arananGun $arananAyAdi"; // Örn: "05 Ağustos"
      String aramaMetni2 = "$arananGun.$arananAyRakam"; // Örn: "05.08"

      bool menuVarMi = snapshot.docs.any((doc) {
        String dbTarih = doc['tarih'].toString();
        // İki formattan biri varsa kabul et!
        return dbTarih.contains(aramaMetni1) || dbTarih.contains(aramaMetni2);
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

                      String arananGun = _seciliTarih.day.toString().padLeft(2, '0');
                      String arananAyAdi = _aylar[_seciliTarih.month];
                      String arananAyRakam = _seciliTarih.month.toString().padLeft(2, '0');

                      String aramaMetni1 = "$arananGun $arananAyAdi"; // "05 Ağustos"
                      String aramaMetni2 = "$arananGun.$arananAyRakam"; // "05.08"

                      for (var doc in docs) {
                        String dbTarih = doc['tarih'].toString();
                        // İki formattan biri eşleşiyorsa o günün verisini ekrana bas
                        if (dbTarih.contains(aramaMetni1) || dbTarih.contains(aramaMetni2)) {
                          gunlukVeri = doc.data() as Map<String, dynamic>;
                          seciliBelgeId = doc.id;
                          break;
                        }
                      }

                      List<Map<String, dynamic>> aktifMenu = [];
                      int toplamKalori = 0;

                      if (gunlukVeri != null) {
                        int kaloriyiOku(String kaloriKey) {
                          final deger = gunlukVeri![kaloriKey];

                          if (deger is num) {
                            return deger.toInt();
                          }

                          return int.tryParse(deger?.toString() ?? '') ?? 0;
                        }

                        void yemekEkle(String yemekKey, String kaloriKey) {
                          final yemekAdi =
                              gunlukVeri![yemekKey]?.toString().trim() ?? '';

                          if (yemekAdi.isEmpty) {
                            return;
                          }

                          final kalori = kaloriyiOku(kaloriKey);

                          aktifMenu.add({
                            'ad': yemekAdi,
                            'kalori': kalori,
                          });

                          toplamKalori += kalori;
                        }

                        yemekEkle('corba', 'corba_kalori');
                        yemekEkle('ana_yemek', 'ana_yemek_kalori');
                        yemekEkle(
                          'yardimci_yemek',
                          'yardimci_yemek_kalori',
                        );
                        yemekEkle('tatli', 'tatli_kalori');
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
        GestureDetector(
          onTap: () {
            if (belgeId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yorumları görmek için menü seçilmeli.')),
              );
              return;
            }

            // KİLİDİ AÇTIK: Saat kaç olursa olsun yorumlar okunabilir!
            _yorumlariAc(context, belgeId);
          },
          child: Container(
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

  void _yorumlariAc(BuildContext context, String belgeId) {
    // Saat ve tarih kontrolünü yapıp alt pencereye (BottomSheet) gönderiyoruz
    String? hata = _etkilesimHataMesaji();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => YorumlarBottomSheet(belgeId: belgeId, hataMesaji: hata),
    );
  }

  Future<void> _oyVer(String? belgeId, String alanAdi) async {
    if (belgeId == null || _prefs == null) return;

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
        await _prefs!.setString('oy_$belgeId', alanAdi);
        setState(() {});
        await docRef.update({alanAdi: FieldValue.increment(1)});
      }
      else if (oncekiOy == alanAdi) {
        await _prefs!.remove('oy_$belgeId');
        setState(() {});
        await docRef.update({alanAdi: FieldValue.increment(-1)});
      }
      else {
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

// === DİNAMİK İSİM YAPISI EKLENMİŞ YORUM PANELİ ===
class YorumlarBottomSheet extends StatefulWidget {
  final String belgeId;
  final String? hataMesaji; // Saat kısıtlamasını kontrol etmek için eklendi

  const YorumlarBottomSheet({Key? key, required this.belgeId, this.hataMesaji}) : super(key: key);

  @override
  State<YorumlarBottomSheet> createState() => _YorumlarBottomSheetState();
}

class _YorumlarBottomSheetState extends State<YorumlarBottomSheet> {
  final TextEditingController _yorumController = TextEditingController();
  final Color primaryBlue = const Color(0xFF003893);
  bool _gonderiliyor = false;
  String _kayitliIsim = 'Kullanıcı';

  @override
  void initState() {
    super.initState();
    _ismiGetir();
  }

  Future<void> _ismiGetir() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // === ANAHTAR BURADA GÜNCELLENDİ ===
      _kayitliIsim = prefs.getString('kullanici_ismi') ?? 'Anonim';
    });
  }

  Future<void> _yorumGonder() async {
    if (_yorumController.text.trim().isEmpty) return;

    setState(() => _gonderiliyor = true);

    try {
      await FirebaseFirestore.instance
          .collection('gunluk_menu')
          .doc(widget.belgeId)
          .collection('yorumlar')
          .add({
        'kullanici_adi': _kayitliIsim,
        'yorum': _yorumController.text.trim(),
        'tarih': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('gunluk_menu')
          .doc(widget.belgeId)
          .update({'yorum_sayisi': FieldValue.increment(1)});

      _yorumController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      print("Yorum gönderme hatası: $e");
    } finally {
      setState(() => _gonderiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Yorumlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('gunluk_menu').doc(widget.belgeId).snapshots(),
              builder: (context, snapshot) {
                int count = 0;
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  count = data['yorum_sayisi'] ?? 0;
                }
                return Text("$count Yorum", style: TextStyle(color: Colors.grey.shade600, fontSize: 13));
              },
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.black12),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('gunluk_menu')
                    .doc(widget.belgeId)
                    .collection('yorumlar')
                    .orderBy('tarih', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: primaryBlue));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("İlk yorumu sen yap!", style: TextStyle(color: Colors.grey)));
                  }

                  var yorumlar = snapshot.data!.docs;
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: yorumlar.length,
                    separatorBuilder: (context, index) => const Divider(height: 24, color: Colors.black12),
                    itemBuilder: (context, index) {
                      var yorumData = yorumlar[index].data() as Map<String, dynamic>;
                      String ad = yorumData['kullanici_adi'] ?? 'Anonim';
                      String metin = yorumData['yorum'] ?? '';

                      String saat = "";
                      if (yorumData['tarih'] != null) {
                        DateTime dt = (yorumData['tarih'] as Timestamp).toDate();
                        saat = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, color: primaryBlue, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(ad, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Text(saat, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(metin, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // EĞER HATA MESAJI YOKSA (SAAT 12-17 ARASIYSA) YORUM KUTUSUNU GÖSTER
            if (widget.hataMesaji == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.black12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: TextField(
                          controller: _yorumController,
                          decoration: const InputDecoration(
                            hintText: "Yorumunuzu yazın...",
                            hintStyle: TextStyle(fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _gonderiliyor ? null : _yorumGonder,
                      child: Container(
                        height: 45,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: _gonderiliyor
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Gönder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            // EĞER SAAT 12-17 ARASI DEĞİLSE (YADA GEÇMİŞ/GELECEK GÜNSE) UYARIYI GÖSTER
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: const Border(top: BorderSide(color: Colors.black12)),
                ),
                child: Text(
                  widget.hataMesaji!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}