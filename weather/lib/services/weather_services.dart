import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '/modules/weather_module.dart';
import 'package:http/http.dart' as http;

class WeatherServices {
  static const baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  final String apiKey;

  WeatherServices(this.apiKey);

  /// Fetch weather data for a given city
  Future<Weather> getWeather(String cityName) async {
    final response = await http.get(
      Uri.parse('$baseUrl?q=$cityName&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data for $cityName');
    }
  }

  /// Get the current city name based on GPS coordinates,
  /// trying the most accurate fields first
  Future<String> getCurrentCity() async {
    // Step 1: Check and request permission for location access
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Step 2: Get current GPS location with high accuracy
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Step 3: Reverse geocode the GPS coordinates to get human-readable address
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    print('📍 Placemark count: ${placemarks.length}');
    print('Placemarks: $placemarks');

    // Step 4: Try the second Placemark first, then the first, and the rest
    List<Placemark> placemarksToCheck = [];

    if (placemarks.length > 1) {
      placemarksToCheck.add(placemarks[1]); // Try the second placemark first
    }
    if (placemarks.isNotEmpty) {
      placemarksToCheck.add(placemarks[0]); // Then the first placemark
    }
    placemarksToCheck.addAll(placemarks.skip(2)); // Add the rest if any

    // Step 5: Try each placemark and get weather data
    for (int i = 0; i < placemarksToCheck.length; i++) {
      Placemark mark = placemarksToCheck[i];
      print('🔎 Trying Placemark [$i]: $mark');

      // Create a list of possible city names from the placemark
      List<String?> cityCandidates = [
        mark.street,
        mark.subLocality, // Good if locality fails (area/neighborhood)
        mark.locality, // Best match (city or town)
        mark.administrativeArea, // Last fallback (state or province)
      ];

      for (String? city in cityCandidates) {
        if (city != null && city.isNotEmpty) {
          print('🌆 Trying city name: $city');
          try {
            // Validate if the city has valid weather data
            await getWeather(city);
            print('✅ Using city: $city from Placemark [$i]');
            return city; // Return the first valid city found
          } catch (e) {
            // If the city doesn't work, print error and continue with the next option
            print('❌ Weather fetch failed for "$city": $e');
          }
        }
      }
    }

    // If no valid city was found, return a default message
    print('⚠️ No valid city found from any Placemark.');
    return "City not found";
  }
}
