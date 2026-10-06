import 'dart:convert';
import 'package:http/http.dart' as http;
import 'shastra_api_models.dart';

class ShastraPanchangamApi {
  static const String baseUrl = 'https://shastrapanchangam.com/api/v1';

  Future<List<ShastraFestival>> getFestivals() async {
    final response = await http.get(Uri.parse('$baseUrl/festivals.json'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final festivalsMap = json['festivals'] as Map<String, dynamic>;
      return festivalsMap.entries
          .map((e) => ShastraFestival.fromJson(e.key, e.value as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load festivals: ${response.statusCode}');
    }
  }

  Future<List<ShastraDayData>> getRange(String cityCode, String fromDate, int days) async {
    final formattedCity = cityCode.toLowerCase().replaceAll(' ', '');
    final response = await http.get(Uri.parse('$baseUrl/range/$formattedCity.json?from=$fromDate&days=$days'));
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final daysList = json['days'] as List<dynamic>?;
      if (daysList == null) return [];
      
      return daysList.map((e) => ShastraDayData.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load range data for $cityCode: ${response.statusCode}');
    }
  }

  Future<ShastraDayData?> getDay(String cityCode, String date) async {
    // Shastra's /day endpoint is currently returning 404. Let's use range for a single day instead.
    try {
      final days = await getRange(cityCode, date, 1);
      if (days.isNotEmpty) {
        return days.first;
      }
    } catch (e) {
      // Fall through
    }
    return null;
  }
}
