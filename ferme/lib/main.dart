import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/session_provider.dart';
import 'screens/app_gate.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('fr_FR');
  runApp(const SuiviFermeApp());
}

class SuiviFermeApp extends StatelessWidget {
  const SuiviFermeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider<SessionProvider>(
          create: (context) => SessionProvider(
            context.read<AuthService>(),
            context.read<FirestoreService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Suivi Ferme',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AppGate(),
      ),
    );
  }
}
