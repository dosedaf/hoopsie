import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {

  static Future<Map<String, double>> getRates() async {
    const url = 'https://open.er-api.com/v6/latest/IDR';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data kurs (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['result'] != 'success') {
      throw Exception('Respons API tidak valid');
    }

    final raw = data['rates'] as Map<String, dynamic>;
    return raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }
}