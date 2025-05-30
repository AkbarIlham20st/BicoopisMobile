import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash.dart';
import 'fleksibel_praktis.dart';
import 'reward_bonus.dart';
import 'penghasilan_tambahan.dart';
import 'login.dart';
import 'lupa_password.dart';
import 'signup.dart';
import 'verifikasi_email.dart';
import 'home.dart';
import 'member.dart';
import 'detail_member.dart';
import 'points.dart';
import 'popup.dart';
import 'notifikasi.dart';
import 'profil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://nfafmiaxogrxxwjuyqfs.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mYWZtaWF4b2dyeHh3anV5cWZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyNTIzMDcsImV4cCI6MjA1NTgyODMwN30.tsapVtnxkicRa-eTQLhKTBQtm7H9U1pfwBBdGdqryW0',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hilangkan label debug
      title: 'Affiliate App',
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/fleksibel_praktis': (context) => FleksibelPraktisScreen(),
        '/reward_bonus': (context) => RewardBonusScreen(),
        '/penghasilan_tambahan': (context) => PenghasilanTambahanScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
     
    );
  }
}
