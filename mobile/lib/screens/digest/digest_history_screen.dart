import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/digest.dart';
import '../../models/article.dart';
import '../../services/firestore_service.dart';
import '../../widgets/article_card.dart';

class DigestHistoryScreen extends StatelessWidget {
  const DigestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des digests')),
      body: StreamBuilder<List<Digest>>(
        stream: firestoreService.watchDigestHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final digests = snapshot.data!;
          if (digests.isEmpty) {
            return const Center(child: Text('Aucun digest disponible pour le moment.'));
          }
          return ListView.separated(
            itemCount: digests.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final digest = digests[index];
              final totalArticles = digest.articlesParAngle.values.fold<int>(0, (a, b) => a + b.length);
              return ListTile(
                title: Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(digest.date)),
                subtitle: Text('$totalArticles articles · ${digest.frequence}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => _DigestDetailScreen(digest: digest)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DigestDetailScreen extends StatelessWidget {
  const _DigestDetailScreen({required this.digest});

  final Digest digest;

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(title: Text(DateFormat('d MMMM yyyy', 'fr_FR').format(digest.date))),
      body: FutureBuilder<List<Article>>(
        future: firestoreService.fetchArticlesByIds(digest.syntheseGlobale),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final articles = snapshot.data!;
          if (articles.isEmpty) {
            return const Center(child: Text('Aucun article marquant pour ce digest.'));
          }
          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) => ArticleCard(article: articles[index], showAngleBadge: true),
          );
        },
      ),
    );
  }
}
