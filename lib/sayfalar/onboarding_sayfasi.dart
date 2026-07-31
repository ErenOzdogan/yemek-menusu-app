import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'anasayfa.dart'; // Ana sayfa ile aynı klasörde olduğumuz için doğrudan bağlıyoruz

class OnboardingSayfasi extends StatefulWidget {
  const OnboardingSayfasi({Key? key}) : super(key: key);

  @override
  State<OnboardingSayfasi> createState() => _OnboardingSayfasiState();
}

class _OnboardingSayfasiState extends State<OnboardingSayfasi> {
  bool _isChecked = false;

  final TextEditingController _adController = TextEditingController();
  final TextEditingController _soyadController = TextEditingController();

  final Color primaryBlue = const Color(0xFF003893);
  final Color cardTitleBlue = const Color(0xFF1565C0);
  final Color lightBlueBg = const Color(0xFFE3F2FD);
  final Color textGray = const Color(0xFF616161);

  Future<void> _veriyiKaydetVeDevamEt() async {
    if (_adController.text.trim().isEmpty || _soyadController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen ad ve soyad alanlarını doldurunuz!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devam etmek için veri saklama onayını vermelisin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final tamIsim = '${_adController.text.trim()} ${_soyadController.text.trim()}';
    await prefs.setString('kullanici_ismi', tamIsim);

    if (!mounted) return;

    // ESKİ BİLDİRİM YERİNE DOĞRUDAN ANA SAYFAYA GEÇİŞ KODU EKLENDİ
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AnaSayfa()),
    );
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
                height: 100,
                color: primaryBlue,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 85,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          children: [
                            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            const SizedBox(height: 4),
                            Text(
                              "Logo yüklenemedi.\npubspec.yaml kontrol edin.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "HOŞ GELDİNİZ!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Akıllı Menü ve Geri Bildirim Sistemi",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuCard(
                          icon: Icons.room_service,
                          title: "Günlük Menü",
                          subtitle: "Günlük yemek menüsünü\nkolayca görüntüleyin",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMenuCard(
                          icon: Icons.chat_bubble,
                          title: "Bildirim",
                          subtitle: "O günün yemeğinin ne\nolduğunu bildirim alın",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuCard(
                          icon: Icons.thumbs_up_down,
                          title: "Değerlendir",
                          subtitle: "Değerlendirin\nve\nyorumlayın",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMenuCard(
                          icon: Icons.account_balance_wallet,
                          title: "Bakiye Ekle",
                          subtitle: "Bakiye yükleyin",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(hintText: "Adınız", controller: _adController),
                  const SizedBox(height: 12),
                  _buildTextField(hintText: "Soyadınız", controller: _soyadController),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _isChecked,
                          activeColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (bool? value) {
                            setState(() {
                              _isChecked = value ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Kişisel verilerin bu cihazda saklanmasını kabul ediyorum.",
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _veriyiKaydetVeDevamEt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Devam et",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      height: 135,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: lightBlueBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryBlue, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: cardTitleBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Center(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: textGray,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required String hintText, required TextEditingController controller}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade700),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
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
        size.height * 0.8,
        0,
        0
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}