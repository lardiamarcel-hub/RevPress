import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme_angles.dart';
import '../../models/article.dart';
import '../../services/firestore_service.dart';
import '../../widgets/article_card.dart';

/// Recherche plein texte, contextualisée à l'onglet actif mais permettant
/// aussi d'élargir à tous les onglets.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialAngle});

  final ThemeAngle? initialAngle;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  bool _tousLesOnglets = false;
  List<Article> _allArticles = [];
  List<Article> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tousLesOnglets = widget.initialAngle == null;
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    final firestoreService = context.read<FirestoreService>();
    final articles = await firestoreService.fetchRecentArticles();
    setState(() {
      _allArticles = articles;
      _loading = false;
    });
    _runSearch();
  }

  void _runSearch() {
    final query = _controller.text.trim().toLowerCase();
    setState(() {
      _results = _allArticles.where((article) {
        final matchesAngle = _tousLesOnglets || article.angleThematique == widget.initialAngle;
        if (!matchesAngle) return false;
        if (query.isEmpty) return true;
        return article.titre.toLowerCase().contains(query) ||
            (article.resume?.toLowerCase().contains(query) ?? false) ||
            article.source.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Rechercher un mot-clé, une source…',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (_) => _runSearch(),
        ),
      ),
      body: Column(
        children: [
          if (widget.initialAngle != null)
            SwitchListTile(
              title: const Text('Rechercher dans tous les onglets'),
              value: _tousLesOnglets,
              onChanged: (value) {
                setState(() => _tousLesOnglets = value);
                _runSearch();
              },
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(child: Text('Aucun résultat.'))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) =>
                            ArticleCard(article: _results[index], showAngleBadge: _tousLesOnglets),
                      ),
          ),
        ],
      ),
    );
  }
}
