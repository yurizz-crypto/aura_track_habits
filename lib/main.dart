import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_track/splash_page.dart';
import 'package:google_fonts/google_fonts.dart';

/// App entry point. Initializes environment variables and Supabase before running the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the .env file containing API keys
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    // Access variables using dotenv.env
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Track',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      home: const SplashPage(),
    );
  }
}