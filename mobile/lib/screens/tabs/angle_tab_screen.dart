import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme_angles.dart';
import '../../providers/articles_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/angle_articles_list.dart';

/// Vue générique réutilisée par les 5 onglets thématiques.
class AngleTabScreen extends StatelessWidget {
  const AngleTabScreen({super.key, required this.angle});

  final ThemeAngle angle;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ArticlesProvider>(
      create: (context) => ArticlesProvider(context.read<FirestoreService>(), angle),
      child: const AngleArticlesList(),
    );
  }
}
