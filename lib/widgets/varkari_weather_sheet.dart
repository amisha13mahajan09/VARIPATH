import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';

/// Modal bottom sheet providing interactive, Varkari-friendly weather advisory.
class VarkariWeatherSheet extends StatefulWidget {
  final WeatherData? initialCurrentWeather;
  final WeatherData? initialPandharpurWeather;
  final double currentLat;
  final double currentLng;
  final VoidCallback onRefreshRequested;

  const VarkariWeatherSheet({
    super.key,
    required this.initialCurrentWeather,
    required this.initialPandharpurWeather,
    required this.currentLat,
    required this.currentLng,
    required this.onRefreshRequested,
  });

  static void show(
    BuildContext context, {
    required WeatherData? currentWeather,
    required WeatherData? pandharpurWeather,
    required double currentLat,
    required double currentLng,
    required VoidCallback onRefresh,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VarkariWeatherSheet(
        initialCurrentWeather: currentWeather,
        initialPandharpurWeather: pandharpurWeather,
        currentLat: currentLat,
        currentLng: currentLng,
        onRefreshRequested: onRefresh,
      ),
    );
  }

  @override
  State<VarkariWeatherSheet> createState() => _VarkariWeatherSheetState();
}

class _VarkariWeatherSheetState extends State<VarkariWeatherSheet>
    with SingleTickerProviderStateMixin {
  static const Color orange = Color(0xFFD8620F);
  static const Color blue = Color(0xFF2D4678);
  static const Color cardBg = Color(0xFFFFFBF7);

  late TabController _tabController;
  WeatherData? _currentWeather;
  WeatherData? _pandharpurWeather;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentWeather = widget.initialCurrentWeather;
    _pandharpurWeather = widget.initialPandharpurWeather;

    if (_pandharpurWeather == null) {
      _loadPandharpurWeather();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPandharpurWeather() async {
    final weather = await WeatherService().fetchPandharpurWeather();
    if (mounted) {
      setState(() {
        _pandharpurWeather = weather;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    final cur = await WeatherService().fetchWeather(
      widget.currentLat,
      widget.currentLng,
      forceRefresh: true,
    );
    final pan = await WeatherService().fetchPandharpurWeather(forceRefresh: true);
    if (mounted) {
      setState(() {
        _currentWeather = cur;
        _pandharpurWeather = pan;
        _isRefreshing = false;
      });
    }
    widget.onRefreshRequested();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Sheet Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: orange.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.wb_sunny_rounded, color: orange, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'हवामान मार्गदर्शक',
                          style: TextStyle(
                            fontFamily: 'YatraOne',
                            fontSize: 18,
                            color: blue,
                          ),
                        ),
                        Text(
                          'Varkari Route Weather & Advisory',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Refresh Weather',
                  onPressed: _isRefreshing ? null : _handleRefresh,
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: orange),
                        )
                      : const Icon(Icons.refresh_rounded, color: blue, size: 24),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Location Tabs: Current Location vs Pandharpur
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: blue.withValues(alpha: 0.1)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: blue,
                labelStyle: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: '📍 चालू स्थान (Live)'),
                  Tab(text: '🚩 पंढरपूर (Destination)'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tab View Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 480,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWeatherDetails(_currentWeather, isDestination: false),
                    _buildWeatherDetails(_pandharpurWeather, isDestination: true),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails(WeatherData? weather, {required bool isDestination}) {
    if (weather == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(color: orange, strokeWidth: 2.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Fetching live weather data...',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Temperature & Condition Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                weather.conditionColor.withValues(alpha: 0.12),
                weather.conditionColor.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: weather.conditionColor.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: weather.conditionColor,
                          height: 1.0,
                        ),
                      ),
                      const Text(
                        'C',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    weather.conditionText,
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: blue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'भासणारे (Feels like): ${weather.apparentTemperature.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: weather.conditionColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: weather.conditionColor.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  weather.conditionIcon,
                  color: weather.conditionColor,
                  size: 38,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Varkari Safety & Walking Advisory Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: weather.conditionColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: weather.conditionColor.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.health_and_safety_rounded, color: weather.conditionColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'वारकरी सुरक्षा सल्ला (Pilgrim Advisory)',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: weather.conditionColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                weather.varkariAdvisory,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: blue,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                weather.varkariTip,
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 4 Key Metrics Grid
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF1976D2),
                label: 'आर्द्रता (Humidity)',
                value: '${weather.humidity}%',
                subtitle: weather.humidity > 70 ? 'High' : 'Normal',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.grain_rounded,
                iconColor: const Color(0xFF0288D1),
                label: 'पाऊस (Rain)',
                value: '${weather.precipitation.toStringAsFixed(1)} mm',
                subtitle: weather.precipitation > 0 ? 'Active' : 'No Rain',
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.air_rounded,
                iconColor: const Color(0xFF00796B),
                label: 'वारा (Wind Speed)',
                value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
                subtitle: weather.windSpeed > 20 ? 'Breezy' : 'Gentle',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.thermostat_rounded,
                iconColor: orange,
                label: 'अंदाज (Category)',
                value: weather.temperature >= 32 ? 'उष्ण (Warm)' : 'सुखद (Pleasant)',
                subtitle: isDestination ? 'At Pandharpur' : 'At Your Location',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: blue.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Lexend',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: blue,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
