import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/article_query.dart';
import '../../models/feed.dart';
import '../../models/folder.dart';
import '../../providers/library_provider.dart';
import '../articles/article_list_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import 'feed_form_screen.dart';

/// Écran d'accueil façon Feedly : « Tous les articles », « Favoris », puis
/// les dossiers et leurs flux. Tout est géré depuis ici — ajouter, modifier,
/// supprimer, importer une sélection de sources.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Future<void> _importCuratedSources(BuildContext context) async {
    final library = context.read<LibraryProvider>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Import des sources en cours…')),
          ],
        ),
      ),
    );
    final result = await library.importCuratedSources();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    final message = result.echecs.isEmpty
        ? '${result.ajoutes} sources importées.'
        : '${result.ajoutes} sources importées, ${result.echecs.length} introuvables '
            '(${result.echecs.join(', ')}).';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revue Éco BF'),
        actions: [
          IconButton(
            tooltip: 'Rechercher',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import') _importCuratedSources(context);
              if (value == 'reglages') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'import', child: Text('Importer une sélection de sources')),
              PopupMenuItem(value: 'reglages', child: Text('Réglages')),
            ],
          ),
        ],
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, library, _) {
          if (library.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final nonClasses = library.feedsInFolder(null);
          final estVide = library.folders.isEmpty && library.feeds.isEmpty;

          return Column(
            children: [
              if (library.syncingAll) const LinearProgressIndicator(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => library.refreshAll(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.dynamic_feed),
                        title: const Text('Tous les articles'),
                        trailing: _UnreadBadge(count: library.unreadCountTotal),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ArticleListScreen(query: ArticleQuery.all)),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.star_border),
                        title: const Text('Favoris'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ArticleListScreen(query: ArticleQuery.favorites)),
                        ),
                      ),
                      const Divider(),
                      if (estVide)
                        const _EmptyState()
                      else ...[
                        for (final folder in library.folders)
                          _FolderSection(
                            title: folder.nom,
                            folder: folder,
                            feeds: library.feedsInFolder(folder.id),
                          ),
                        if (nonClasses.isNotEmpty)
                          _FolderSection(title: 'Non classés', folder: null, feeds: nonClasses),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ajouter un journal ou un flux',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FeedFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FolderSection extends StatelessWidget {
  const _FolderSection({required this.title, required this.feeds, required this.folder});

  final String title;
  final List<Feed> feeds;
  final Folder? folder;

  Future<void> _rename(BuildContext context, LibraryProvider library) async {
    final controller = TextEditingController(text: folder!.nom);
    final nom = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer le dossier'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (nom != null && nom.isNotEmpty) {
      await library.renameFolder(folder!.id, nom);
    }
  }

  Future<void> _delete(BuildContext context, LibraryProvider library) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce dossier ?'),
        content: Text('« ${folder!.nom} » sera supprimé. Ses flux redeviendront non classés.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed == true) {
      await library.deleteFolder(folder!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.read<LibraryProvider>();
    return ExpansionTile(
      initiallyExpanded: true,
      title: Row(
        children: [
          Expanded(child: Text(title)),
          if (folder != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) {
                if (value == 'renommer') _rename(context, library);
                if (value == 'supprimer') _delete(context, library);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'renommer', child: Text('Renommer')),
                PopupMenuItem(value: 'supprimer', child: Text('Supprimer le dossier')),
              ],
            ),
        ],
      ),
      children: feeds.isEmpty
          ? const [Padding(padding: EdgeInsets.all(16), child: Text('Aucun flux dans ce dossier.'))]
          : feeds.map((feed) => _FeedTile(feed: feed)).toList(),
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({required this.feed});

  final Feed feed;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final unread = library.unreadCountForFeed(feed.id);
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 32, right: 8),
      leading: const Icon(Icons.rss_feed, size: 20),
      title: Text(feed.nom, overflow: TextOverflow.ellipsis),
      subtitle: feed.derniereErreur != null
          ? Text(
              'Erreur : ${feed.derniereErreur}',
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnreadBadge(count: unread),
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => FeedFormScreen(existing: feed)),
            ),
          ),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ArticleListScreen(query: ArticleQuery.feed(feed.id, feed.nom))),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.rss_feed, size: 48, color: Theme.of(context).disabledColor),
          const SizedBox(height: 12),
          const Text(
            "Aucun flux pour l'instant.\n\n"
            'Ajoutez un journal ou un magazine avec le bouton "+", ou importez une '
            'sélection de sources burkinabè et régionales depuis le menu en haut à droite.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
