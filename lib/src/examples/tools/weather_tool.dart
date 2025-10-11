import '../../core/result.dart';
import '../../core/tool.dart';

/// A mock weather tool that simulates weather API calls.
///
/// This is a demonstration tool that returns simulated weather data.
/// In a real application, you would:
/// 1. Make HTTP requests to a weather API (e.g., OpenWeatherMap, WeatherAPI)
/// 2. Parse the response
/// 3. Return formatted weather information
///
/// Example integration with a real API:
/// ```dart
/// class RealWeatherTool extends Tool {
///   final String apiKey;
///   final http.Client client;
///
///   @override
///   Future<ToolResult> execute(Map<String, dynamic> params) async {
///     final location = params['location'] as String;
///     final response = await client.get(
///       Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$location&appid=$apiKey'),
///     );
///     // Parse and return weather data
///   }
/// }
/// ```
class WeatherTool extends Tool {
  /// Whether to use mock data (true) or fail indicating real API needed (false).
  final bool useMockData;

  WeatherTool({this.useMockData = true});

  @override
  String get name => 'get_weather';

  @override
  String get description =>
      'Gets current weather information for a specified location. '
      'Provides temperature, conditions, humidity, and wind speed.';

  @override
  Map<String, dynamic> get parameterSchema => {
        'type': 'object',
        'properties': {
          'location': {
            'type': 'string',
            'description':
                'The location to get weather for (e.g., "London", "New York, NY", "Tokyo, Japan")',
          },
          'units': {
            'type': 'string',
            'enum': ['celsius', 'fahrenheit'],
            'description': 'Temperature units (default: celsius)',
          },
        },
        'required': ['location'],
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> params) async {
    try {
      final location = params['location'] as String?;
      final units = params['units'] as String? ?? 'celsius';

      if (location == null || location.isEmpty) {
        return ToolResult.failure(
          toolName: name,
          error: 'Location parameter is required and cannot be empty',
        );
      }

      if (!useMockData) {
        return ToolResult.failure(
          toolName: name,
          error:
              'This is a mock weather tool. Integrate with a real weather API '
              '(e.g., OpenWeatherMap, WeatherAPI) for production use.',
          metadata: {
            'suggestion': 'Set an API key and implement real API calls',
          },
        );
      }

      // Generate mock weather data
      final weatherData = _generateMockWeather(location, units);

      return ToolResult.success(
        toolName: name,
        data: weatherData,
        metadata: {
          'is_mock': true,
          'fetched_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      return ToolResult.failure(
        toolName: name,
        error: 'Failed to get weather: $e',
      );
    }
  }

  @override
  bool canHandle(String query) {
    final lowerQuery = query.toLowerCase();
    return lowerQuery.contains('weather') ||
        lowerQuery.contains('temperature') ||
        lowerQuery.contains('forecast') ||
        lowerQuery.contains('rain') ||
        lowerQuery.contains('sunny') ||
        lowerQuery.contains('cloudy');
  }

  /// Generates mock weather data for demonstration purposes.
  Map<String, dynamic> _generateMockWeather(String location, String units) {
    // Simple hash to get consistent "random" values for the same location
    final hash = location.hashCode.abs();

    // Generate temperature based on location hash
    final tempCelsius = 10 + (hash % 25);
    final tempFahrenheit = (tempCelsius * 9 / 5) + 32;

    final conditions = [
      'Sunny',
      'Partly Cloudy',
      'Cloudy',
      'Rainy',
      'Clear',
      'Overcast'
    ];
    final condition = conditions[hash % conditions.length];

    final humidity = 40 + (hash % 50);
    final windSpeed = 5 + (hash % 20);

    return {
      'location': location,
      'temperature': units == 'fahrenheit'
          ? tempFahrenheit.toStringAsFixed(1)
          : tempCelsius.toStringAsFixed(1),
      'units': units,
      'condition': condition,
      'humidity': '$humidity%',
      'wind_speed': '$windSpeed km/h',
      'feels_like': units == 'fahrenheit'
          ? (tempFahrenheit - 2).toStringAsFixed(1)
          : (tempCelsius - 2).toStringAsFixed(1),
      'timestamp': DateTime.now().toIso8601String(),
      'description':
          'Current weather in $location is $condition with a temperature of '
              '${units == 'fahrenheit' ? tempFahrenheit.toStringAsFixed(1) + '°F' : tempCelsius.toStringAsFixed(1) + '°C'}. '
              'Humidity is at $humidity% and wind speed is $windSpeed km/h.',
    };
  }
}
