// lib/main.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://luiyhilklrumohktsfwa.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx1aXloaWxrbHJ1bW9oa3RzZndhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0MjI5NjUsImV4cCI6MjA5Mzk5ODk2NX0.om8jxIvZsDF2ns04-JDbh15AVdxdKdcEbcnsq-81_5o',
  );

  runApp(const FineDineApp());
}

class FineDineApp extends StatelessWidget {
  const FineDineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fine-Dine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}