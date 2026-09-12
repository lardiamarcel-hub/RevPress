import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'db/feed_repository.dart';
import 'providers/library_provider.dart';
import 'screens/library/library_screen.dart';
import 'services/feed_sync_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  runApp(const RevueEcoBfApp());
}

class RevueEcoBfApp extends StatelessWidget {
  const RevueEcoBfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FeedRepository>(create: (_) => FeedRepository()),
        ChangeNotifierProvider<LibraryProvider>(
          create: (context) => LibraryProvider(
            repository: context.read<FeedRepository>(),
            syncService: FeedSyncService(repository: context.read<FeedRepository>()),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Revue Éco BF',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const LibraryScreen(),
      ),
    );
  }
}
