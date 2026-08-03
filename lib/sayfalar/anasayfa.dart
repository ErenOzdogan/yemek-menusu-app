import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'yemek_menusu_sayfasi.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ayarlar_sayfasi.dart';

// BİLDİRİM SERVİSİNİ EKLEDİK (Ana sayfadan da alarmı kapatıp açabilmek için)
import 'package:belediye_menu_app/services/bildirim_servisi.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({Key? key}) : super(key: key);

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  String _kullaniciIsmi = "Eren Özdoğan";
  bool _bildirimAcik = true;

  @override
  void initState() {
    super.initState();
    _hafizadanVerileriOku();
  }

  // YENİLENDİ: Artık sadece ismi değil, bildirimin açık/kapalı durumunu da hafızadan çekiyor
  Future<void> _hafizadanVerileriOku() async {
    final prefs = await SharedPreferences.getInstance();
    final kayitliIsim = prefs.getString('kullanici_ismi');
    final bildirimDurumu = prefs.getBool('bildirim_acik') ?? true; // Ayarlardaki durumu öğren

    setState(() {
      if (kayitliIsim != null && kayitliIsim.isNotEmpty) {
        _kullaniciIsmi = kayitliIsim;
      }
      _bildirimAcik = bildirimDurumu; // Butonu ona göre açık veya kapalı göster
    });
  }

  // YENİ EKLENDİ: Ana sayfadaki switch değiştiğinde her şeyi güncelleyen fonksiyon
  Future<void> _bildirimDurumunuDegistir(bool yeniDeger) async {
    setState(() {
      _bildirimAcik = yeniDeger;
    });

    final prefs = await SharedPreferences.getInstance();

    // 1. Yeni durumu hafızaya kaydet (Böylece ayarlara gidince senkronize olur)
    await prefs.setBool('bildirim_acik', yeniDeger);

    // 2. Alarm kurmak/iptal etmek için saat verilerini hafızadan çek
    String birinciSaat = prefs.getString('birinci_saat') ?? '17:00';
    String ikinciSaat = prefs.getString('ikinci_saat') ?? '10:00';

    // 3. Bildirim servisine yeni durumu yolla (Eğer kapandıysa alarmlar iptal olur)
    await BildirimServisi.alarmlariGuncelle(yeniDeger, birinciSaat, ikinciSaat);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(yeniDeger ? 'Bildirimler açıldı 🔔' : 'Bildirimler kapatıldı 🔕'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _bakiyeYuklemeSayfasiniAc() async {
    final Uri url = Uri.parse('https://yemekhaneodeme.kahramanmaras.bel.tr');
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
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: BottomWaveClipper(),
              child: Container(
                height: 140,
                color: const Color(0xFF003893),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          height: 70,
                          fit: BoxFit.contain,
                        ),
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
                              // YENİLENDİ: Ayarlardan geri dönüldüğünde hafızayı tekrar okumasını sağladık
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AyarlarSayfasi()),
                                );
                                _hafizadanVerileriOku(); // Sayfa kapanıp geri gelindiğinde switch'i güncelle
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
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
                    _kullaniciIsmi,
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
                  _buildActionCard(
                    backgroundColor: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF2E7D32),
                    icon: Icons.account_balance_wallet,
                    title: "Bakiye Ekle",
                    subtitle: "Hesabınıza hızlıca\nbakiye yükleyin",
                    onTap: () {
                      _bakiyeYuklemeSayfasiniAc();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildToggleCard(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
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
            Icon(Icons.arrow_forward_ios, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }

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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: elementColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications, color: elementColor, size: 28),
          ),
          const SizedBox(width: 16),
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
          Switch(
            value: _bildirimAcik,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF003893),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade400,
            onChanged: (value) {
              // YENİLENDİ: Artık direkt setState yapmak yerine bizim yazdığımız detaylı fonksiyonu çağırıyoruz
              _bildirimDurumunuDegistir(value);
            },
          ),
        ],
      ),
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