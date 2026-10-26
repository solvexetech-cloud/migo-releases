import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  /// ഒരു ടെക്സ്റ്റിനെ ലക്ഷ്യ ഭാഷയിലേക്ക് വിവർത്തനം ചെയ്യുന്നു.
  /// [targetLang] ഉദാ: 'ar' (അറബിക്), 'en' (ഇംഗ്ലീഷ്)
  Future<String> translate(String text, String targetLang) async {
    if (text.trim().isEmpty) return '';
    try {
      // സൗജന്യ Google Translate API എൻഡ്പോയിന്റ്
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}',
      );
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // റെസ്പോൺസിൽ നിന്ന് വിവർത്തനം ചെയ്ത ടെക്സ്റ്റ് എടുക്കുന്നു
        final translatedText = data[0][0][0] as String;
        return translatedText;
      } else {
        print('Translation failed: ${response.statusCode}');
        return text; // പരാജയപ്പെട്ടാൽ ഒറിജിനൽ ടെക്സ്റ്റ് തിരികെ നൽകുക
      }
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }
}