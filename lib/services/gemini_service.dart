import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final String apiKey =
        dotenv.env['GEMINI_API_KEY']?.trim() ?? '';

    if (apiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY bulunamadı. .env dosyasını kontrol et.',
      );
    }

    _model = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: apiKey,
    );
  }

  Future<Map<String, dynamic>> kaloriHesapla(
      List<String> yemekler,
      ) async {
    final temizYemekler = yemekler
        .map((yemek) => yemek.trim())
        .where((yemek) => yemek.isNotEmpty)
        .toList();

    if (temizYemekler.isEmpty) {
      return {};
    }

    final prompt = '''
Aşağıdaki yemeklerin yaklaşık porsiyon kalorilerini hesapla.

${temizYemekler.join('\n')}

Yemek adlarını mümkün olduğunca verilen şekliyle kullan.
Sadece geçerli JSON döndür.
Açıklama, markdown veya kod bloğu ekleme.

Örnek:

{
  "Mercimek Çorbası": 150,
  "Etli Nohut": 420,
  "Pirinç Pilavı": 280,
  "Ayran": 90
}
''';

    final response = await _model.generateContent([
      Content.text(prompt),
    ]);

    String cevap = response.text?.trim() ?? '{}';

    // Gemini bazen JSON'u ```json kod bloğu içerisinde döndürebilir.
    cevap = cevap
        .replaceFirst(RegExp(r'^```json\s*'), '')
        .replaceFirst(RegExp(r'^```\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();

    final dynamic jsonSonucu = jsonDecode(cevap);

    if (jsonSonucu is! Map) {
      throw const FormatException(
        'Gemini geçerli bir JSON nesnesi döndürmedi.',
      );
    }

    return Map<String, dynamic>.from(jsonSonucu);
  }
}