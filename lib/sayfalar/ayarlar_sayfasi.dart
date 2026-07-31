import 'package:flutter/material.dart';

class AyarlarSayfasi extends StatefulWidget {
  const AyarlarSayfasi({Key? key}) : super(key: key);

  @override
  State<AyarlarSayfasi> createState() => _AyarlarSayfasiState();
}

class _AyarlarSayfasiState extends State<AyarlarSayfasi> {
  // Bildirimlerin genel kontrolü
  bool _bildirimlerAcik = true;

  // Seçili olan saatleri String olarak tutuyoruz (Başlangıç değerleri)
  String _birinciSaat = '15:00';
  String _ikinciSaat = '10:00';

  // Dil seçeneği
  String _seciliDil = 'Türkçe';

  // 1. Bildirim için sadece 13:00 - 23:00 arası seçenekler
  final List<String> _birinciSaatSecenekleri = [
    '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30', '20:00', '20:30',
    '21:00', '21:30', '22:00', '22:30', '23:00'
  ];

  // 2. Bildirim için sadece 00:00 - 11:00 arası seçenekler
  final List<String> _ikinciSaatSecenekleri = [
    '00:00', '00:30', '01:00', '01:30', '02:00', '02:30', '03:00', '03:30',
    '04:00', '04:30', '05:00', '05:30', '06:00', '06:30', '07:00', '07:30',
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // SAYFAYI STACK (KATMAN) İÇİNE ALDIK
      body: Stack(
        children: [
          // 1. KATMAN: EN ALTTAKİ MAVİ DALGA (Arka Plan)
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: BottomWaveClipper(), // Senin yazdığın makas sınıfı
              child: Container(
                height: 120, // Dalganın boyu (İstediğin gibi azaltıp artırabilirsin)
                color: const Color(0xFF003893), // Belediyenin kurumsal mavisi (hafif saydam)
              ),
            ),
          ),

          // 2. KATMAN: SAYFANIN ASIL İÇERİĞİ (Ön Plan)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // --- TEPEDEKİ LOGO VE GERİ BUTONU ---
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF003893)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Image.asset(
                        'assets/logo.png', // DİKKAT: Logonun tam adı neyse ona göre düzelt!
                        height: 55,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 1. BİLDİRİMLER SWITCH KARTI
                  _buildCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F0FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.notifications, color: Color(0xFF1553B4)),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              "Bildirimler",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        Switch(
                          value: _bildirimlerAcik,
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF1553B4),
                          onChanged: (value) {
                            setState(() {
                              _bildirimlerAcik = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. BİRİNCİ BİLDİRİM SAATİ KARTI
                  AnimatedOpacity(
                    opacity: _bildirimlerAcik ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !_bildirimlerAcik,
                      child: _buildTimeDropdownCard(
                        title: "1. BİLDİRİM SAATİ",
                        selectedTime: _birinciSaat,
                        timeOptions: _birinciSaatSecenekleri,
                        onChanged: (String? yeniSaat) {
                          if (yeniSaat != null) {
                            setState(() {
                              _birinciSaat = yeniSaat;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. İKİNCİ BİLDİRİM SAATİ KARTI
                  AnimatedOpacity(
                    opacity: _bildirimlerAcik ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !_bildirimlerAcik,
                      child: _buildTimeDropdownCard(
                        title: "2. BİLDİRİM SAATİ",
                        selectedTime: _ikinciSaat,
                        timeOptions: _ikinciSaatSecenekleri,
                        onChanged: (String? yeniSaat) {
                          if (yeniSaat != null) {
                            setState(() {
                              _ikinciSaat = yeniSaat;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. DİL SEÇENEĞİ KARTI
                  _buildCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F0FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.language, color: Color(0xFF1553B4)),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              "Dil Seçeneği",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _seciliDil,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1553B4)),
                              style: const TextStyle(color: Color(0xFF1553B4), fontWeight: FontWeight.bold),
                              items: <String>['Türkçe', 'English']
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _seciliDil = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kart iskeletini oluşturan fonksiyon
  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Dropdown'a daha iyi oturması için dikey boşluğu biraz kıstık
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  // Saatler için yeni hazırladığımız Açılır Menü (Dropdown) Kartı
  Widget _buildTimeDropdownCard({
    required String title,
    required String selectedTime,
    required List<String> timeOptions,
    required ValueChanged<String?> onChanged,
  }) {
    return _buildCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedTime,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1553B4)),
              dropdownColor: Colors.white,
              menuMaxHeight: 250, // Açılır menü çok uzun olup ekranı kaplamasın diye kaydırılabilir bir yükseklik verdik
              items: timeOptions.map((String time) {
                return DropdownMenuItem<String>(
                  value: time,
                  child: Text(time),
                );
              }).toList(),
              onChanged: onChanged,
            ),
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

