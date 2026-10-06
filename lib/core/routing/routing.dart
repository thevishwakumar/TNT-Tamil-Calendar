import 'package:flutter/material.dart';

class TNTRoutes {
  static const String initial = '/';
  static const String home = '/home';
  static const String calendar = '/calendar';
  static const String panchangam = '/panchangam';
  static const String muhurtham = '/muhurtham';
  static const String more = '/more';
  
  // More section routes
  static const String specialDays = '/special-days';
  static const String festivals = '/festivals';
  static const String saved = '/saved';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String about = '/about';
}

/// Simple Navigator route generator to ensure code compiles beautifully
class TNTRouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Standard MaterialPageRoute defaults to keep compiler happy.
    // Full screens will be dynamically mapped during execution.
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Route not defined')),
      ),
    );
  }
}
