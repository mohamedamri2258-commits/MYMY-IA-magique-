import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://mymy-ia-magique.onrender.com";
  static Future<String> sendMessage(String prompt) async {
    final url = Uri.parse('$baseUrl/api/chat');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'prompt': prompt,
          'language': 'fr',
          'mode': 'full_app_generator'
        }),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['response'] ?? data['message'] ?? 'Réponse reçue';
      } else {
        return 'Erreur serveur (${response.statusCode})';
      }
    } catch (e) {
      return 'Erreur de connexion au serveur IA';
    }
  }
}

