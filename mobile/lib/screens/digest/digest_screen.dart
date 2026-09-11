import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/digest_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/article_card.dart';

class DigestScreen extends StatelessWidget {
  const DigestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DigestProvider>(
      create: (context) => DigestProvider(context.read<FirestoreService>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Digest du jour')),
        body: Consumer<DigestProvider>(
          builder: (context, provider, _) {
            if (provider.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.todayDigest == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    "Le digest du jour n'a pas encore été généré.\nIl sera prêt après la prochaine collecte planifiée.",
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (provider.topArticles.isEmpty) {
              return const Center(child: Text('Aucun article marquant aujourd\'hui.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: provider.topArticles.length,
              itemBuilder: (context, index) => ArticleCard(
                article: provider.topArticles[index],
                showAngleBadge: true,
              ),
            );
          },
        ),
      ),
    );
  }
}
