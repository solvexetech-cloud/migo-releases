import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  // TODO: നിങ്ങളുടെ Google Cloud Translation API Key ഇവിടെ നൽകുക
  static const String _apiKey = 'YOUR_API_KEY_HERE';

  /// ഒരു ടെക്സ്റ്റിനെ ലക്ഷ്യ ഭാഷയിലേക്ക് വിവർത്തനം ചെയ്യുന്നു.
  /// [targetLang] ഉദാ: 'ar' (അറബിക്), 'en' (ഇംഗ്ലീഷ്)
  Future<String> translate(String text, String targetLang) async {
    if (text.trim().isEmpty) return '';
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      print('Translation API Key not set. Returning original text.');
      return text; // API Key ഇല്ലെങ്കിൽ ഒറിജിനൽ ടെക്സ്റ്റ് തിരികെ നൽകുക
    }
    try {
      final url = Uri.parse(
        'https://translation.googleapis.com/language/translate/v2?key=$_apiKey',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'target': targetLang,
          'format': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['translations'][0]['translatedText'] as String;
      } else {
        print('Translation failed: ${response.statusCode} - ${response.body}');
        return text;
      }
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }
}