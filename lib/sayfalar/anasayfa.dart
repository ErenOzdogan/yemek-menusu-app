import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'yemek_menusu_sayfasi.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ayarlar_sayfasi.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({Key? key}) : super(key: key);

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  // Hafızadan isim gelene kadar veya hafıza boşsa görünecek varsayılan isim
  String _kullaniciIsmi = "Eren Özdoğan";
  bool _bildirimAcik = true;

  @override
  void initState() {
    super.initState();
    _ismiHafizadanOku();
  }

  // Onboarding'de kaydettiğimiz ismi hafızadan çeken fonksiyon
  Future<void> _ismiHafizadanOku() async {
    final prefs = await SharedPreferences.getInstance();
    final kayitliIsim = prefs.getString('kullanici_ismi');

    if (kayitliIsim != null && kayitliIsim.isNotEmpty) {
      setState(() {
        _kullaniciIsmi = kayitliIsim;
      });
    }
  }

  // Tarayıcıyı açacak olan asenkron (Future) fonksiyon
  Future<void> _bakiyeYuklemeSayfasiniAc() async {
    // BURADAKİ LİNKİ BELEDİYENİN GERÇEK ÖDEME SAYFASIYLA DEĞİŞTİRDİK
    final Uri url = Uri.parse('https://yemekhaneodeme.kahramanmaras.bel.tr');

    // Linki telefonun harici (kendi) tarayıcısında aç
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sayfa açılamadı, lütfen internet bağlantınızı kontrol edin.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. KATMAN: EN ALTTAKİ MAVİ DALGA
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: BottomWaveClipper(),
              child: Container(
                height: 140,
                color: const Color(0xFF003893), // Kurumsal Koyu Mavi
              ),
            ),
          ),

          // 2. KATMAN: SAYFA İÇERİĞİ
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // ÜST KISIM: LOGO VE AYARLAR BUTONU
                  SizedBox(
                    width: double.infinity, // Alanı tüm ekrana yayar, butonu sağa iter
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Orijinal Logomuz (Tam ortada)
                        Image.asset(
                          'assets/logo.png',
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                        // Sağdaki Ayarlar İkonu (Ekranın en sağına yaslı)
                        Positioned(
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.settings, color: Color(0xFF003893)),
                              onPressed: () {
                                // YENİ EKLENEN SAYFA GEÇİŞ KODU BURADA
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AyarlarSayfasi()),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // PROFİL FOTOĞRAFI ALANI
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.person, size: 60, color: Color(0xFF003893)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // HOŞ GELDİNİZ YAZISI VE İSİM (Hafızadan Okunan)
                  const Text(
                    "Hoş geldiniz,",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _kullaniciIsmi, // Hafızadan gelen dinamik isim burada gösteriliyor
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003893),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Akıllı Menü ve Geri Bildirim Sistemi",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // MENÜ BUTONLARI (KARTLAR)

                  // 1. Yemek Menüsü Butonu (Mavi Tema)
                  _buildActionCard(
                    backgroundColor: const Color(0xFFF2F6FE),
                    iconColor: const Color(0xFF1553B4),
                    icon: Icons.room_service,
                    title: "Yemek Menüsü",
                    subtitle: "Günün yemek menüsünü\ngörüntüleyin",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const YemekMenusuSayfasi()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Bakiye Ekle Butonu(yeşil tema)
                  _buildActionCard(
                    backgroundColor: const Color(0xFFE8F5E9), // Canlı açık yeşil arka plan
                    iconColor: const Color(0xFF2E7D32), // Koyu yeşil ikon ve vurgu rengi
                    icon: Icons.account_balance_wallet,
                    title: "Bakiye Ekle",
                    subtitle: "Hesabınıza hızlıca\nbakiye yükleyin",
                    onTap: () {
                      _bakiyeYuklemeSayfasiniAc(); // Yönlendirme kodumuz kusursuz çalışıyor
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Bildirim Butonu (Sarı/Turuncu Tema - Switch'li)
                  _buildToggleCard(),

                  const SizedBox(height: 80), // Alt kavisin butonları örtmemesi için boşluk
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tıklanabilir, Ok İşaretli Standart Kart Tasarımı (Yemek Menüsü ve Bakiye İçin)
  Widget _buildActionCard({
    required Color backgroundColor,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Sol İkon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            // Orta Metinler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: iconColor.withOpacity(0.7),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Sağ Ok İkonu
            Icon(Icons.arrow_forward_ios, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }

  // Switch (Aç/Kapa) Özellikli Bildirim Kartı Tasarımı
  Widget _buildToggleCard() {
    final Color cardColor = const Color(0xFFFFF9EE);
    final Color elementColor = const Color(0xFFD48806);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Sol İkon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: elementColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications, color: elementColor, size: 28),
          ),
          const SizedBox(width: 16),
          // Orta Metinler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Bildirim",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: elementColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Yemek bildirimlerini açıp kapatın",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: elementColor.withOpacity(0.7),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Sağ Switch (Aç/Kapa Butonu)
          Switch(
            value: _bildirimAcik,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF003893), // Açıkken Mavi
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade400,
            onChanged: (value) {
              setState(() {
                _bildirimAcik = value;
              });
              // Kullanıcıya bilgi ver
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value ? 'Bildirimler açıldı 🔔' : 'Bildirimler kapatıldı 🔕'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Ekranın Altındaki Kavisli Mavi Dalga
class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.quadraticBezierTo(
        size.width / 2,
        size.height * 0.7,
        0,
        0
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}