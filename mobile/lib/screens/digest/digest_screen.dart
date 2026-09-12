import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/digest_provider.dart';
import '../../services/cloud_functions_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/article_card.dart';

class DigestScreen extends StatelessWidget {
  const DigestScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    final result = await context.read<CloudFunctionsService>().manualRefresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

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
            return RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: provider.todayDigest == null
                  ? _buildMessage(
                      "Le digest du jour n'a pas encore été généré.\nTirez vers le bas pour le générer maintenant.",
                    )
                  : provider.topArticles.isEmpty
                      ? _buildMessage("Aucun article marquant aujourd'hui.")
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: provider.topArticles.length,
                          itemBuilder: (context, index) => ArticleCard(
                            article: provider.topArticles[index],
                            showAngleBadge: true,
                          ),
                        ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessage(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
