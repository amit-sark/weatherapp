import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:weather/modules/weather_module.dart';
import 'package:weather/services/weather_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _weatherService = WeatherServices('84651da6c7125ed3a6d4ed6bfb903aff');
  Weather? _weather;

  // Fetch the weather data
  _fetchWeather() async {
    String cityName = await _weatherService.getCurrentCity();

    try {
      final weather = await _weatherService.getWeather(cityName);
      setState(() {
        _weather = weather;
      });
    } catch (e) {
      print(e);
    }
  }

  // Get the animation based on the weather condition
  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'assets/loading.json';

    switch (mainCondition.toLowerCase()) {
      case 'rain':
        return 'assets/rain.json';
      case 'clouds':
        return 'assets/cloud.json';
      case 'thunderstorm':
        return 'assets/storm.json';
      case 'clear':
        return 'assets/sunny.json';
      case 'drizzle':
        return 'assets/rain.json';
      default:
        return 'assets/sunny.json';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeather(); // Fetch weather data as soon as the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Location icon appears only if the weather data is available
              if (_weather != null) ...[
                const Icon(Icons.location_on),
                const SizedBox(height: 10),
                Text(
                  _weather?.cityName ?? "",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Weather Animation
              Expanded(
                flex: 3,
                child: Lottie.asset(
                  getWeatherAnimation(_weather?.mainCondition),
                  fit: BoxFit.contain,
                ),
              ),

              // Temperature Display
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    _weather != null
                        ? '${_weather!.temperature.round()}°C'
                        : '', // Display temperature if data is available
                    style: const TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
