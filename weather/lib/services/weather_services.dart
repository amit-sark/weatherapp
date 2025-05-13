import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '/modules/weather_module.dart';
import 'package:http/http.dart' as http;

class WeatherServices {
  static const baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  final String apiKey;

  WeatherServices(this.apiKey);

  Future<Weather> getWeather(String cityName) async {
    final response = await http.get(
      Uri.parse('$baseUrl?q=$cityName&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<String> getCurrentCity() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    print('Full address list: $placemarks');

    for (Placemark mark in placemarks) {
      List<String?> options = [
        mark.name,
        mark.street,
        mark.subLocality,
        mark.locality,
        mark.administrativeArea,
      ];

      for (String? city in options) {
        if (city != null && city.isNotEmpty) {
          print("➡️ Trying location field: $city");

          try {
            await getWeather(city);
            print("✅ City Found: $city");
            return city;
          } catch (e) {
            print("❌ Failed to load weather for $city, trying next option...");
          }
        }
      }
    }

    print("⚠️ No valid city found");
    return "City not found";
  }
}
