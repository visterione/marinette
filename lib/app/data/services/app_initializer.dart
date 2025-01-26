import 'package:flutter/material.dart';

class AppInitializer {
  static Future<void> initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();
  }
}
